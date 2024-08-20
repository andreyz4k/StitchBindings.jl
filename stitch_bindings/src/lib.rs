use ::stitch_core::*;
use clap::Parser;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn compress_backend_c(
    programs: *const *const c_char,
    program_count: usize,
    tasks: *const *const c_char,
    task_count: usize,
    name_mapping: *const *const c_char,
    name_mapping_count: usize,
    panic_loud: bool,
    args: *const c_char,
) -> *mut c_char {
    // Convert C types to Rust types
    let programs: Vec<String> = unsafe {
        std::slice::from_raw_parts(programs, program_count)
            .iter()
            .map(|&p| CStr::from_ptr(p).to_string_lossy().into_owned())
            .collect()
    };
    let tasks: Option<Vec<String>> = if task_count > 0 {
        Some(unsafe {
            std::slice::from_raw_parts(tasks, task_count)
                .iter()
                .map(|&t| CStr::from_ptr(t).to_string_lossy().into_owned())
                .collect()
        })
    } else {
        None
    };
    let weights: Option<Vec<f32>> = None;
    let name_mapping: Option<Vec<(String, String)>> = if name_mapping_count > 0 {
        Some(unsafe {
            std::slice::from_raw_parts(name_mapping, name_mapping_count)
                .iter()
                .map(|&nm| {
                    let binding = CStr::from_ptr(nm).to_string_lossy();
                    let mut parts = binding.splitn(2, ',');
                    let from = parts.next().unwrap().to_string();
                    let to = parts.next().unwrap().to_string();
                    (from, to)
                })
                .collect()
        })
    } else {
        None
    };

    // disable the printing of panics, so that the only panic we see is the one that gets passed along in an Exception to Python
    if !panic_loud {
        std::panic::set_hook(Box::new(|_| {}));
    }

    let cfg = match MultistepCompressionConfig::try_parse_from(
        format!(
            "compress {}",
            unsafe { CStr::from_ptr(args) }.to_string_lossy()
        )
        .split_whitespace(),
    ) {
        Ok(cfg) => cfg,
        Err(e) => panic!("Error parsing arguments: {}", e),
    };

    // release the GIL and call compression
    let (_step_results, json_res) =
        multistep_compression(&programs, tasks, weights, name_mapping, None, &cfg);

    // return as something you could JSON.parse(out) from in Julia
    let res = CString::new(json_res.to_string()).expect("CString::new failed");

    res.into_raw()
}

#[no_mangle]
pub extern "C" fn free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(s);
    }
}
