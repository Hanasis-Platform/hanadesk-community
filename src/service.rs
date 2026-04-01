use libhanadesk::*;

#[cfg(not(target_os = "macos"))]
fn main() {}

#[cfg(target_os = "macos")]
fn main() {
    crate::common::load_custom_client();
    crate::common::apply_build_mode();
    crate::ui_interface::refresh_options();
    hbb_common::init_log(false, "service");
    crate::start_os_service();
}
