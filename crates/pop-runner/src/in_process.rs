//! Bounded in-process driver for iOS and embedded hosts (PopKit).
//! QuickJS runs with tight heap/stack limits (16 MiB heap, 512 KiB stack, 250 ms interrupt
//! deadline for authored commands; zero host I/O). Native raster work runs on the caller's
//! background thread.
use super::*;

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

/// Tight heap budget for in-process authored commands on mobile/embedded hosts.
pub const IN_PROCESS_COMMAND_HEAP_BYTES: usize = 16 << 20;
/// Cooperative interrupt deadline for in-process authored commands.
pub const IN_PROCESS_COMMAND_TIMEOUT_MS: u64 = 250;

#[derive(Clone, Debug)]
pub struct Evaluator {
    executable: PathBuf,
    allow_commands: bool,
}
impl Evaluator {
    /// Capture-only in-process driver: authored commands remain explicitly refused.
    pub fn new(executable: PathBuf) -> Result<Self, Error> {
        Self::with_policy(executable, false)
    }
    /// Bounded in-process driver allowing both Takumi capture and authored `commands.ts`
    /// evaluation under tight QuickJS memory/stack/time caps with zero host I/O.
    pub fn new_with_commands(executable: PathBuf) -> Result<Self, Error> {
        Self::with_policy(executable, true)
    }
    fn with_policy(executable: PathBuf, allow_commands: bool) -> Result<Self, Error> {
        if !executable.is_absolute() {
            return Err(Error::Spawn("In-process evaluator requires an absolute host binary path".into()));
        }
        Ok(Self { executable, allow_commands })
    }
    pub fn supports_commands(&self) -> bool {
        self.allow_commands
    }
    pub fn executable_path(&self) -> &Path {
        &self.executable
    }
    pub fn run(&self, runtime_abi: u64, bundle: &str, request: &str) -> Result<String, Error> {
        if !self.allow_commands {
            return Err(Error::Sandbox("Authored commands are unavailable in the in-process capture driver".into()));
        }
        if bundle.len().saturating_add(request.len()) > pop_contracts::evaluator::INPUT {
            return Err(Error::Output("Command input is too large".into()));
        }
        let deadline = Instant::now() + Duration::from_millis(IN_PROCESS_COMMAND_TIMEOUT_MS);
        evaluation::evaluate_command_bounded(
            runtime_abi,
            bundle,
            request,
            IN_PROCESS_COMMAND_HEAP_BYTES,
            move || Instant::now() >= deadline,
        )
    }
    pub fn markup(&self, runtime_abi: u64, bundle: &str, request: &str, widget: bool) -> Result<Batch, Error> {
        if bundle.len().saturating_add(request.len()) > pop_contracts::evaluator::INPUT {
            return Err(Error::Output("Capture input is too large".into()));
        }
        let deadline = Instant::now() + Duration::from_millis(pop_contracts::evaluator::EXECUTION_MS);
        evaluation::prelude(runtime_abi)?;
        crate::capture::evaluate_markup(
            bundle,
            request,
            if widget { "__popWidget" } else { "__popCapture" },
            move || Instant::now() >= deadline,
        )
    }

    pub fn raster(
        &self,
        runtime_abi: u64,
        batch: Batch,
        images: BTreeMap<String, Vec<u8>>,
        mode: JobKind,
    ) -> Result<Vec<Vec<u8>>, Error> {
        evaluation::prelude(runtime_abi)?;
        if !matches!(mode, JobKind::Widget | JobKind::Capture) {
            return Err(Error::Output("In-process capture supports PNG artwork and widget images only".into()));
        }
        batch.validate().map_err(program_error)?;
        crate::render::raster(batch, images, mode)
    }
}
