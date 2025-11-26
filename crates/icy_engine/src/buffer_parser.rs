//! Compatibility layer for the old BufferParser trait
//! 
//! This module provides backward compatibility for code that depends on the BufferParser trait
//! which was removed when the codebase transitioned to the new parser infrastructure.

use crate::{EditableScreen, EngineResult};

/// Old BufferParser trait for backward compatibility with icy_net and other dependencies
/// 
/// This trait is a compatibility shim for code that was written against the older parser
/// infrastructure. New code should use the new parser infrastructure from icy_parser_core instead.
pub trait BufferParser: Send {
    /// Get the next action to perform on the buffer
    fn get_next_action(&mut self, _buffer: &mut dyn EditableScreen) -> Option<CallbackAction> {
        None
    }

    /// Prints a character to the buffer
    ///
    /// # Errors
    ///
    /// This function will return an error if character processing fails
    fn print_char(&mut self, buffer: &mut dyn EditableScreen, c: char) -> EngineResult<CallbackAction>;
}

/// Action to be performed after character processing
#[derive(Debug, PartialEq, Clone)]
pub enum CallbackAction {
    None,
    Update,
    Beep,
}
