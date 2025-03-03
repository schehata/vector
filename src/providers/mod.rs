#![allow(missing_docs)]
use enum_dispatch::enum_dispatch;
use vector_config::{configurable_component, NamedComponent};

use crate::{
    config::{ConfigBuilder, ProviderConfig},
    signal,
};

pub mod http;

pub type BuildResult = std::result::Result<ConfigBuilder, Vec<String>>;

/// Configurable providers in Vector.
#[configurable_component]
#[derive(Clone, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
#[enum_dispatch(ProviderConfig)]
pub enum Providers {
    /// HTTP.
    Http(http::HttpConfig),
}

// We can't use `enum_dispatch` here because it doesn't support associated constants.
impl NamedComponent for Providers {
    const NAME: &'static str = "_invalid_usage";

    fn get_component_name(&self) -> &'static str {
        match self {
            Self::Http(config) => config.get_component_name(),
        }
    }
}
