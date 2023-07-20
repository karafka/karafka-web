# Karafka Web changelog

## 0.7.0 (Unreleased)
- **[Feature]** Introduce graphs.
- **[Feature]** Introduce historical metrics storage.
- **[Feature]** Introduce per-topic data exploration in the Explorer.
- [Improvement] List Web UI topics names on the status page in the info section.
- [Improvement] Start versioning the materialized states schemas.
- [Improvement] Drastically improve the consumers view performance.
- [Improvement] Ship versioned assets to prevent invalid assets loading due to cache.
- [Improvement] Use `Cache-Control` to cache all the static assets.
- [Improvement] Link `counters` counter to jobs page.
- [Improvement] Include a sticky footer with the most important links and copyrights.
- [Improvement] Store lag in counters for performance improvement and historical metrics.
- [Improvement] Move top navbar content to the left to gain space for new features.
- [Improvement] Introduce in-memory cluster state cached to improve performance.
- [Improvement] Switch to offset based pagination instead of per-page pagination.
- [Improvement] Avoid double-reading of watermark offsets for explorer and errors display.
- [Improvement] When no params needed for a page, do not include empty params.
- [Improvement] Do not include page when page is 1 in the url.
- [Fix] Fix headers size inconsistency between Health and Routing.
- [Refactor] Reorganize pagination engine to support offset based pagination.

## 0.6.1 (2023-06-25)
- [Improvement] Include the karafka-web version in the status page tags.
- [Improvement] Report `karafka-web` version that is running in particular processes.
- [Improvement] Display `karafka-web` version in the per-process view.
- [Improvement] Report in the web-ui a scenario, where getting cluster info takes more than 500ms as a warning to make people realize, that operating with Kafka with extensive latencies is not recommended.
- [Improvement] Continue the status assessment flow on warnings.
- [Fix] Do not recommend running a server as a way to bootstrap the initial state.
- [Fix] Ensure in the report contract, that `karafka-core`, `karafka-web`, `rdkafka` and `librdkafka` are validated.

## 0.6.0 (2023-06-13)
- **[Feature]** Introduce producers errors tracking.
- [Improvement] Display the error origin as a badge to align with consumers view topic assignments.
- [Improvement] Collect more job metrics for future usage.
- [Improvement] Normalize order of job columns on multiple views.
- [Improvement] Improve pagination by providing a "Go to first page" fast button.
- [Improvement] Provide more explicit info in the consumers view when no consumers running.
- [Improvement] Validate error reporting with unified error contract.
- [Improvement] Use estimated errors count for counters presentation taken from the errors topic instead of materialization via consumers states to allow for producers errors tracking.
- [Improvement] Introduce `schema_version` to error reports.
- [Improvement] Do not display the dispatched error message offset in the breadcrumb and title as it was confused with the error message content.
- [Improvement] Display `error_class` value wrapped with code tag.
- [Improvement] Display error `type` value wrapped with label tag.
- [Improvement] Include a blurred backtrace for non-Pro error inspection as a form of indication of this Pro feature.
- [Fix] Fix invalid arrows style in the pagination.
- [Fix] Fix missing empty `Process name` value in the errors index view.
- [Fix] Fix potential empty dispatch of consumer metrics.
- [Fix] Remove confusing part about real time resources from the "Pro feature" page.
- [Refactor] Cleanup common components for errors extraction.
- [Refactor] Remove not used and redundant partials.
- [Maintenance] Require `karafka` `2.1.4` due to fixes in metrics usage for workless flows.

### Upgrade notes

Because of the reporting schema update, it is recommended to:

- First, deploy **all** the Karafka consumer processes (`karafka server`)
- Deploy the Web update to your web server.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error or offset related data may not be displayed correctly.

#### Disabling producers instrumentation

Producers error tracking **is** enabled by default. If you want to opt out of it, you need to disable the producers' instrumentation by clearing the producers' listeners:

```ruby
Karafka::Web.setup do |config|
  # Do not instrument producers with web-ui listeners
  config.tracking.producers.listeners = []
end
```

#### Custom producers instrumentation

By default, Karafka Web-UI instruments only `Karafka.producer`. If you use producers initialized by yourself, you need to connect the listeners to them manually. To do so, run the following code:

```ruby
::Karafka::Web.config.tracking.producers.listeners.each do |listener|
  MY_CUSTOM_PRODUCER.monitor.subscribe(listener)
end
```

Please make sure **not** to do it for the default `Karafka.producer` because it is instrumented out of the box.

## 0.5.2 (2023-05-22)
- [Improvement] Label ActiveJob consumers jobs with `active_job` tag.
- [Improvement] Label Virtual Partitions consumers with `virtual` tag.
- [Improvement] Label Long Running Jobs with `long_running_job` tag.
- [Improvement] Label collapsed Virtual Partition with `collapsed` tag.
- [Improvement] Display consumer tags always below the consumer class name in Jobs/Consumer Jobs views.
- [Improvement] Add label with the attempt count on work being retried.

## 0.5.1 (2023-04-16)
- [Fix] Use CSP header matching Sidekiq one to ensure styles and js loading (#55)

## 0.5.0 (2023-04-13)
- [Improvement] Report job `-1001` offsets as `N/A` as in all the other places.
- [Fix] Fix misspelling of word `committed`.
- [Fix] Shutdown and revocation jobs statistics extraction crashes when idle initialized without messages (#53)

### Upgrade notes

Because of the reporting schema change, it is recommended to:

- First, deploy **all** the Karafka consumer processes (`karafka server`)
- Deploy the Web update to your web server.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error or offset related data may not be displayed correctly.

## 0.4.1 (2023-04-12)
- [Improvement] Replace the "x time ago" in the code explorer with an exact date (`2023-04-12 10:16:48.596 +0200 `).
- [Improvement] When hovering over a message timestamp, a label with raw numeric timestamp will be presented.
- [Improvement] Do not skip reporting on partitions subscribed that never received any messages.
- [Fix] Skip reporting data on subscriptions that were revoked and not only stopped by us.

## 0.4.0 (2023-04-07)
- [Improvement] Include active jobs and active partitions subscriptions count in the per-process tab navigation.
- [Improvement] Include subscription groups names in the per-process subscriptions view.
- [Fix] Add missing support for using multiple subscription groups within a single consumer group.
- [Fix] Mask SASL credentials in topic routing view (#46)

### Upgrade notes

Because of the reporting schema change, it is recommended to:

- First, deploy **all** the Karafka consumer processes (`karafka server`)
- Deploy the Web update to your web server.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error.

## 0.3.1 (2023-03-27)
- [Fix] Add missing retention policy for states topic.
- [Fix] Fix display of compacted messages placeholders for offsets lower than low watermark.
- [Fix] Fix invalid pagination per page count.

### Upgrade notes

If upgrading from `0.3.0`, nothing.

If upgrading from lower, please follow `0.3.0` upgrade procedure.

## 0.3.0 (2023-03-27)
- **[Feature]** Support paginating over compacted topics partitions.
- [Improvement] Display watermark offsets in the errors view.
- [Improvement] Display informative message when partition is empty due to a retention policy.
- [Improvement] Display informative message when partition is empty instead of displaying nothing.
- [Improvement] Display current watermark offsets in the Explorer when viewing list of messages from a given partition.
- [Improvement] Report extra debug info in the status section.
- [Improvement] Report not only `Karafka` and `WaterDrop` versions but also `Karafka::Core`, `Rdkafka` and `librdkafka` versions.
- [Improvement] Small CSS improvements.
- [Improvement] Provide nicer info when errors topic does not contain any errors or was compacted.
- [Improvement] Improve listing of errors including compacted once.
- [Fix] Fix pagination for compacted indexes that would display despite no data being available below the low watermark offset.
- [Fix] Fix a case where reading from a compacted offset would return no data despite data being available.
- [Fix] Fix a case where explorer pagination would suggest more pages for compacted topics.
- [Fix] Fix incorrect support of compacted partitions and partitions with low watermark offset other than 0.
- [Fix] Display `N/A` instead of `-1` and `-1001` on lag stored and stored offset for consumer processes that did not mark any messages as consumed yet in the per consumer view.
- [Maintenance] Remove compatibility fallbacks for job and process tags (#1342)
- [Maintenance] Extract base sampler for tracking and web.

### Upgrade notes

Because of the removal of compatibility fallbacks for some metrics fetches, it is recommended to:

- First, deploy **all** the Karafka consumer processes (`karafka server`)
- Deploy the Web update to your web server.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error.

## 0.2.5 (2023-03-17)
- [Fix] Critical instrumentation async errors intercepted by Web don't have JID for job removal (#1366)

## 0.2.4 (2023-03-14)
- [Improvement] Paginate topics list in cluster info on every 100 partitions.
- [Improvement] Provide current page in the pagination.
- [Improvement] Report usage of Karafka Pro on the status page view.
- [Fix] Add missing three months limit on errors storage.
- [Maintenance] Exclude Karafka Web UI topics from declarative topics.

## 0.2.3 (2023-03-04)
- [Improvement] Snapshot current consumer tags upon consumer errors.
- [Improvement] Optimize exception message extraction from errors.
- [Improvement] Slightly change error reporting structure (backwards compatible) to collect process tags on errors and to align with other reports.

## 0.2.2 (2023-02-25)
- [Fix] Fix status page reference in Pro.

## 0.2.1 (2023-02-24)
- [Fix] Fix format incompatibility between 0.1.x and 0.2.x data formats. This will allow for the 0.2 Web UI to work with 0.1.x reporting.

## 0.2.0 (2023-02-24)
- **[Feature]** Introduce ability to tag `Karafka::Process` to display process-centric tags in the Web UI.
- **[Feature]** Introduce ability to tag consumer instances to display consumption-centric tags in the Web UI.
- **[Feature]** Introduce a /status page that can validate the setup and tell what is missing (#1318)
- [Improvement] Allow for disabling the consumer subscription from Web for multi-tenant Web UI usage (#1331)
- [Improvement] Make sure that states and reports are always dispatched to the partition `0`. This should prevent UI from not fully working when someone accidentally creates more partitions than expected.
- [Fix] Fix a bug where bootstrapping would create two initial states.
- [Fix] Fix a case, where errors listener would try to force encoding on a frozen error message.

## 0.1.3 (2023-02-14)
- Skip topics creation if web topics already exist (do not raise error)
- Support ability to provide replication factor in the install command
- Provide ability to reset the state with a `reset` command. It will remove and re-create the topics.
- Provide ability to uninstall the web via the CLI `uninstall` command
- Remove the `Karafka::Web.bootstrap!` method as the install should happen via `bundle exec karafka-web install`

## 0.1.2 (2023-02-10)
- Provide more comprehensive info when lag stored and stored offset are not available.
- Setup rspec scaffold.

## 0.1.1 (2023-01-30)
- Rename `Karafka::Web.bootstrap_topics!` to `Karafka::Web.bootstrap!` and expand it with the zero state injection.
- Require Karafka `2.0.28` due to some instrumentation fixes.
- Provide an auto-installer under the `bundle exec karafka-web install` command.

## 0.1.0
- Initial code of the Web and Web Pro.
