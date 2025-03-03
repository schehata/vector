package metadata

base: components: sinks: splunk_hec_logs: configuration: {
	acknowledgements: {
		description: "Splunk HEC acknowledgement configuration."
		required:    false
		type: object: options: {
			enabled: {
				description: """
					Whether or not end-to-end acknowledgements are enabled.

					When enabled for a sink, any source connected to that sink, where the source supports
					end-to-end acknowledgements as well, will wait for events to be acknowledged by the sink
					before acknowledging them at the source.

					Enabling or disabling acknowledgements at the sink level takes precedence over any global
					[`acknowledgements`][global_acks] configuration.

					[global_acks]: https://vector.dev/docs/reference/configuration/global-options/#acknowledgements
					"""
				required: false
				type: bool: {}
			}
			indexer_acknowledgements_enabled: {
				description: """
					Controls if the sink will integrate with [Splunk HEC indexer acknowledgements][splunk_indexer_ack_docs] for end-to-end acknowledgements.

					[splunk_indexer_ack_docs]: https://docs.splunk.com/Documentation/Splunk/8.2.3/Data/AboutHECIDXAck
					"""
				required: false
				type: bool: default: true
			}
			max_pending_acks: {
				description: """
					The maximum number of pending acknowledgements from events sent to the Splunk HEC collector.

					Once reached, the sink will begin applying backpressure.
					"""
				required: false
				type: uint: default: 1000000
			}
			query_interval: {
				description: "The amount of time to wait between queries to the Splunk HEC indexer acknowledgement endpoint."
				required:    false
				type: uint: {
					default: 10
					unit:    "seconds"
				}
			}
			retry_limit: {
				description: "The maximum number of times an acknowledgement ID will be queried for its status."
				required:    false
				type: uint: default: 30
			}
		}
	}
	auto_extract_timestamp: {
		description: """
			Passes the `auto_extract_timestamp` option to Splunk.

			This option is only relevant to Splunk v8.x and above, and is only applied when
			`endpoint_target` is set to `event`.

			Setting this to `true` will cause Splunk to extract the timestamp from the message text
			rather than use the timestamp embedded in the event. The timestamp must be in the format
			`yyyy-mm-dd hh:mm:ss`.
			"""
		required: false
		type: bool: {}
	}
	batch: {
		description: "Event batching behavior."
		required:    false
		type: object: options: {
			max_bytes: {
				description: """
					The maximum size of a batch that will be processed by a sink.

					This is based on the uncompressed size of the batched events, before they are
					serialized / compressed.
					"""
				required: false
				type: uint: {
					default: 1000000
					unit:    "bytes"
				}
			}
			max_events: {
				description: "The maximum size of a batch before it is flushed."
				required:    false
				type: uint: unit: "events"
			}
			timeout_secs: {
				description: "The maximum age of a batch before it is flushed."
				required:    false
				type: float: {
					default: 1.0
					unit:    "seconds"
				}
			}
		}
	}
	compression: {
		description: """
			Compression configuration.

			All compression algorithms use the default compression level unless otherwise specified.
			"""
		required: false
		type: string: {
			default: "none"
			enum: {
				gzip: """
					[Gzip][gzip] compression.

					[gzip]: https://www.gzip.org/
					"""
				none: "No compression."
				zlib: """
					[Zlib][zlib] compression.

					[zlib]: https://zlib.net/
					"""
			}
		}
	}
	default_token: {
		description: """
			Default Splunk HEC token.

			If an event has a token set in its secrets (`splunk_hec_token`), it will prevail over the one set here.
			"""
		required: true
		type: string: {}
	}
	encoding: {
		description: "Configures how events are encoded into raw bytes."
		required:    true
		type: object: options: {
			avro: {
				description:   "Apache Avro-specific encoder options."
				relevant_when: "codec = \"avro\""
				required:      true
				type: object: options: schema: {
					description: "The Avro schema."
					required:    true
					type: string: examples: ["{ \"type\": \"record\", \"name\": \"log\", \"fields\": [{ \"name\": \"message\", \"type\": \"string\" }] }"]
				}
			}
			codec: {
				description: "The codec to use for encoding events."
				required:    true
				type: string: enum: {
					avro: """
						Encodes an event as an [Apache Avro][apache_avro] message.

						[apache_avro]: https://avro.apache.org/
						"""
					gelf: """
						Encodes an event as a [GELF][gelf] message.

						[gelf]: https://docs.graylog.org/docs/gelf
						"""
					json: """
						Encodes an event as [JSON][json].

						[json]: https://www.json.org/
						"""
					logfmt: """
						Encodes an event as a [logfmt][logfmt] message.

						[logfmt]: https://brandur.org/logfmt
						"""
					native: """
						Encodes an event in Vector’s [native Protocol Buffers format][vector_native_protobuf].

						This codec is **[experimental][experimental]**.

						[vector_native_protobuf]: https://github.com/vectordotdev/vector/blob/master/lib/vector-core/proto/event.proto
						[experimental]: https://vector.dev/highlights/2022-03-31-native-event-codecs
						"""
					native_json: """
						Encodes an event in Vector’s [native JSON format][vector_native_json].

						This codec is **[experimental][experimental]**.

						[vector_native_json]: https://github.com/vectordotdev/vector/blob/master/lib/codecs/tests/data/native_encoding/schema.cue
						[experimental]: https://vector.dev/highlights/2022-03-31-native-event-codecs
						"""
					raw_message: """
						No encoding.

						This "encoding" simply uses the `message` field of a log event.

						Users should take care if they're modifying their log events (such as by using a `remap`
						transform, etc) and removing the message field while doing additional parsing on it, as this
						could lead to the encoding emitting empty strings for the given event.
						"""
					text: """
						Plain text encoding.

						This "encoding" simply uses the `message` field of a log event. For metrics, it uses an
						encoding that resembles the Prometheus export format.

						Users should take care if they're modifying their log events (such as by using a `remap`
						transform, etc) and removing the message field while doing additional parsing on it, as this
						could lead to the encoding emitting empty strings for the given event.
						"""
				}
			}
			except_fields: {
				description: "List of fields that will be excluded from the encoded event."
				required:    false
				type: array: items: type: string: {}
			}
			metric_tag_values: {
				description: """
					Controls how metric tag values are encoded.

					When set to `single`, only the last non-bare value of tags will be displayed with the
					metric.  When set to `full`, all metric tags will be exposed as separate assignments.
					"""
				relevant_when: "codec = \"json\" or codec = \"text\""
				required:      false
				type: string: {
					default: "single"
					enum: {
						full: "All tags will be exposed as arrays of either string or null values."
						single: """
															Tag values will be exposed as single strings, the same as they were before this config
															option. Tags with multiple values will show the last assigned value, and null values will be
															ignored.
															"""
					}
				}
			}
			only_fields: {
				description: "List of fields that will be included in the encoded event."
				required:    false
				type: array: items: type: string: {}
			}
			timestamp_format: {
				description: "Format used for timestamp fields."
				required:    false
				type: string: enum: {
					rfc3339: "Represent the timestamp as a RFC 3339 timestamp."
					unix:    "Represent the timestamp as a Unix timestamp."
				}
			}
		}
	}
	endpoint: {
		description: """
			The base URL of the Splunk instance.

			The scheme (`http` or `https`) must be specified. No path should be included since the paths defined
			by the [`Splunk`][splunk] API are used.

			[splunk]: https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/HECRESTendpoints
			"""
		required: true
		type: string: examples: ["https://http-inputs-hec.splunkcloud.com", "https://hec.splunk.com:8088", "http://example.com"]
	}
	endpoint_target: {
		description: "Splunk HEC endpoint configuration."
		required:    false
		type: string: {
			default: "event"
			enum: {
				event: """
					Events are sent to the [event endpoint][event_endpoint_docs].

					When the event endpoint is used, configured [event metadata][event_metadata_docs] is sent
					directly with each event.

					[event_endpoint_docs]: https://docs.splunk.com/Documentation/Splunk/8.0.0/RESTREF/RESTinput#services.2Fcollector.2Fevent
					[event_metadata_docs]: https://docs.splunk.com/Documentation/Splunk/latest/Data/FormateventsforHTTPEventCollector#Event_metadata
					"""
				raw: """
					Events are sent to the [raw endpoint][raw_endpoint_docs].

					When the raw endpoint is used, configured [event metadata][event_metadata_docs] is sent as
					query parameters on the request, except for the `timestamp` field.

					[raw_endpoint_docs]: https://docs.splunk.com/Documentation/Splunk/8.0.0/RESTREF/RESTinput#services.2Fcollector.2Fraw
					[event_metadata_docs]: https://docs.splunk.com/Documentation/Splunk/latest/Data/FormateventsforHTTPEventCollector#Event_metadata
					"""
			}
		}
	}
	host_key: {
		description: """
			Overrides the name of the log field used to grab the hostname to send to Splunk HEC.

			By default, the [global `log_schema.host_key` option][global_host_key] is used.

			[global_host_key]: https://vector.dev/docs/reference/configuration/global-options/#log_schema.host_key
			"""
		required: false
		type: string: default: "host"
	}
	index: {
		description: """
			The name of the index to send events to.

			If not specified, the default index defined within Splunk is used.
			"""
		required: false
		type: string: {
			examples: ["{{ host }}", "custom_index"]
			syntax: "template"
		}
	}
	indexed_fields: {
		description: """
			Fields to be [added to Splunk index][splunk_field_index_docs].

			[splunk_field_index_docs]: https://docs.splunk.com/Documentation/Splunk/8.0.0/Data/IFXandHEC
			"""
		required: false
		type: array: {
			default: []
			items: type: string: examples: ["field1", "field2"]
		}
	}
	request: {
		description: """
			Middleware settings for outbound requests.

			Various settings can be configured, such as concurrency and rate limits, timeouts, etc.
			"""
		required: false
		type: object: options: {
			adaptive_concurrency: {
				description: """
					Configuration of adaptive concurrency parameters.

					These parameters typically do not require changes from the default, and incorrect values can lead to meta-stable or
					unstable performance and sink behavior. Proceed with caution.
					"""
				required: false
				type: object: options: {
					decrease_ratio: {
						description: """
																The fraction of the current value to set the new concurrency limit when decreasing the limit.

																Valid values are greater than `0` and less than `1`. Smaller values cause the algorithm to scale back rapidly
																when latency increases.

																Note that the new limit is rounded down after applying this ratio.
																"""
						required: false
						type: float: default: 0.9
					}
					ewma_alpha: {
						description: """
																The weighting of new measurements compared to older measurements.

																Valid values are greater than `0` and less than `1`.

																ARC uses an exponentially weighted moving average (EWMA) of past RTT measurements as a reference to compare with
																the current RTT. Smaller values cause this reference to adjust more slowly, which may be useful if a service has
																unusually high response variability.
																"""
						required: false
						type: float: default: 0.4
					}
					rtt_deviation_scale: {
						description: """
																Scale of RTT deviations which are not considered anomalous.

																Valid values are greater than or equal to `0`, and we expect reasonable values to range from `1.0` to `3.0`.

																When calculating the past RTT average, we also compute a secondary “deviation” value that indicates how variable
																those values are. We use that deviation when comparing the past RTT average to the current measurements, so we
																can ignore increases in RTT that are within an expected range. This factor is used to scale up the deviation to
																an appropriate range.  Larger values cause the algorithm to ignore larger increases in the RTT.
																"""
						required: false
						type: float: default: 2.5
					}
				}
			}
			concurrency: {
				description: "Configuration for outbound request concurrency."
				required:    false
				type: {
					string: {
						default: "none"
						enum: {
							adaptive: """
															Concurrency will be managed by Vector's [Adaptive Request Concurrency][arc] feature.

															[arc]: https://vector.dev/docs/about/under-the-hood/networking/arc/
															"""
							none: """
															A fixed concurrency of 1.

															Only one request can be outstanding at any given time.
															"""
						}
					}
					uint: {}
				}
			}
			rate_limit_duration_secs: {
				description: "The time window used for the `rate_limit_num` option."
				required:    false
				type: uint: {
					default: 1
					unit:    "seconds"
				}
			}
			rate_limit_num: {
				description: "The maximum number of requests allowed within the `rate_limit_duration_secs` time window."
				required:    false
				type: uint: {
					default: 9223372036854775807
					unit:    "requests"
				}
			}
			retry_attempts: {
				description: """
					The maximum number of retries to make for failed requests.

					The default, for all intents and purposes, represents an infinite number of retries.
					"""
				required: false
				type: uint: {
					default: 9223372036854775807
					unit:    "retries"
				}
			}
			retry_initial_backoff_secs: {
				description: """
					The amount of time to wait before attempting the first retry for a failed request.

					After the first retry has failed, the fibonacci sequence will be used to select future backoffs.
					"""
				required: false
				type: uint: {
					default: 1
					unit:    "seconds"
				}
			}
			retry_max_duration_secs: {
				description: "The maximum amount of time to wait between retries."
				required:    false
				type: uint: {
					default: 3600
					unit:    "seconds"
				}
			}
			timeout_secs: {
				description: """
					The time a request can take before being aborted.

					It is highly recommended that you do not lower this value below the service’s internal timeout, as this could
					create orphaned requests, pile on retries, and result in duplicate data downstream.
					"""
				required: false
				type: uint: {
					default: 60
					unit:    "seconds"
				}
			}
		}
	}
	source: {
		description: """
			The source of events sent to this sink.

			This is typically the filename the logs originated from.

			If unset, the Splunk collector will set it.
			"""
		required: false
		type: string: {
			examples: ["{{ file }}", "/var/log/syslog", "UDP:514"]
			syntax: "template"
		}
	}
	sourcetype: {
		description: """
			The sourcetype of events sent to this sink.

			If unset, Splunk will default to `httpevent`.
			"""
		required: false
		type: string: {
			examples: ["{{ sourcetype }}", "_json"]
			syntax: "template"
		}
	}
	timestamp_key: {
		description: """
			Overrides the name of the log field used to grab the timestamp to send to Splunk HEC.
			When set to `“”`, vector omits setting a timestamp in the events sent to Splunk HEC.

			By default, the [global `log_schema.timestamp_key` option][global_timestamp_key] is used.

			[global_timestamp_key]: https://vector.dev/docs/reference/configuration/global-options/#log_schema.timestamp_key
			"""
		required: false
		type: string: {
			default: "timestamp"
			examples: ["timestamp", ""]
		}
	}
	tls: {
		description: "TLS configuration."
		required:    false
		type: object: options: {
			alpn_protocols: {
				description: """
					Sets the list of supported ALPN protocols.

					Declare the supported ALPN protocols, which are used during negotiation with peer. Prioritized in the order
					they are defined.
					"""
				required: false
				type: array: items: type: string: examples: ["h2"]
			}
			ca_file: {
				description: """
					Absolute path to an additional CA certificate file.

					The certificate must be in the DER or PEM (X.509) format. Additionally, the certificate can be provided as an inline string in PEM format.
					"""
				required: false
				type: string: examples: ["/path/to/certificate_authority.crt"]
			}
			crt_file: {
				description: """
					Absolute path to a certificate file used to identify this server.

					The certificate must be in DER, PEM (X.509), or PKCS#12 format. Additionally, the certificate can be provided as
					an inline string in PEM format.

					If this is set, and is not a PKCS#12 archive, `key_file` must also be set.
					"""
				required: false
				type: string: examples: ["/path/to/host_certificate.crt"]
			}
			key_file: {
				description: """
					Absolute path to a private key file used to identify this server.

					The key must be in DER or PEM (PKCS#8) format. Additionally, the key can be provided as an inline string in PEM format.
					"""
				required: false
				type: string: examples: ["/path/to/host_certificate.key"]
			}
			key_pass: {
				description: """
					Passphrase used to unlock the encrypted key file.

					This has no effect unless `key_file` is set.
					"""
				required: false
				type: string: examples: ["${KEY_PASS_ENV_VAR}", "PassWord1"]
			}
			verify_certificate: {
				description: """
					Enables certificate verification.

					If enabled, certificates must be valid in terms of not being expired, as well as being issued by a trusted
					issuer. This verification operates in a hierarchical manner, checking that not only the leaf certificate (the
					certificate presented by the client/server) is valid, but also that the issuer of that certificate is valid, and
					so on until reaching a root certificate.

					Relevant for both incoming and outgoing connections.

					Do NOT set this to `false` unless you understand the risks of not verifying the validity of certificates.
					"""
				required: false
				type: bool: {}
			}
			verify_hostname: {
				description: """
					Enables hostname verification.

					If enabled, the hostname used to connect to the remote host must be present in the TLS certificate presented by
					the remote host, either as the Common Name or as an entry in the Subject Alternative Name extension.

					Only relevant for outgoing connections.

					Do NOT set this to `false` unless you understand the risks of not verifying the remote hostname.
					"""
				required: false
				type: bool: {}
			}
		}
	}
}
