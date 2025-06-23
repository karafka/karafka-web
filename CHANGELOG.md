# Karafka Web Changelog

## 0.11.1 (2025-06-23)
- [Fix] Extremely high error turnover from hundreds of partitions can cause a deadlock in the reporter for transactional Web producer.

## 0.11.0 (2025-06-15)
- **[Feature]** Provide ability to pause/resume partitions on running consumers via the UI (Pro).
- **[Feature]** Provide ability to edit offsets of running consumers (Pro).
- **[Feature]** Support consumers that have mismatching schema in the Status page.
- **[Feature]** Provide ability to navigate to a timestamp in the Explorer (Pro).
- **[Feature]** Provide ability to create and delete topics from the Web UI (Pro).
- **[Feature]** Provide ability to manage topics configuration from the Web UI (Pro).
- **[Feature]** Provide ability to manage topics partitioning from the Web UI (Pro).
- **[Feature]** Provide ability to inject custom CSS and JS to adjust the Web UI.
- [Enhancement] Support KIP-82 (header values of arrays).
- [Enhancement] Include crawl-based link validator to the CI to ensure no dead links are generated.
- [Enhancement] Allow for custom links in the navigation (Pro).
- [Enhancement] Optimize topic specific lookups (Pro).
- [Enhancement] Replace simple in-process metadata cache with user tracking version for multi-process deployments improvements.
- [Enhancement] Move web ui topics configuration into config.
- [Enhancement] Upgrade DaisyUI to 5.0 and Tailwind to 4.0.
- [Enhancement] Make consumer sampler/stats gathering compatible across debian/alpine/wolfi OSes (chen-anders)
- [Enhancement] Promote consumers lags statistics chart to OSS.
- [Enhancement] Promote consumers RSS statistics chart to OSS.
- [Enhancement] Remove state cache usage that complicated ability to manage topics.
- [Enhancement] Improve flash messages.
- [Enhancement] Improve handling of post-submit redirects.
- [Enhancement] Provide better support for fully transactional consumers.
- [Enhancement] Error out when `#setup` is called after `#enable!`.
- [Enhancement] Use more performant Kafka API calls to describe topics.
- [Enhancement] Inject `.action-NAME` and `.controller-NAME` body classes for usage with custom CSS and JS.
- [Enhancement] Improve error handling in the commanding iterator listener (Pro).
- [Enhancement] Introduce `trace_id` to the errors tracked for DLQ correlation (if in use) (Pro).
- [Enhancement] Normalize how topics with partitions data is being displayed (`topic-[0,1,2]` etc).
- [Change] Do not fully hide config-disabled features but make them disabled.
- [Change] Remove per-consumer process duplicated details from Subscriptions and Jobs tabs.
- [Change] Move to trusted-publishers and remove signing since no longer needed.
- [Refactor] Make sure all temporary topics have a `it-` prefix in their name.
- [Refactor] Introduce a `bin/verify_topics_naming` script to ensure proper test topics naming convention.
- [Fix] Closest time based lookup redirect fails.
- [Fix] Fi incorrect error type in commanding listener from `web.controlling.controller.error` to `web.commanding.listener.error` (Pro).
- [Fix] Topic named messages collides with the explorer routes.
- [Fix] Fix a case where live poll button enabling would not immediately start refreshes.
- [Fix] Fix negative message deserialization allocation stats.
- [Fix] Fix incorrect background color in some of the alert notices.
- [Fix] Support dark mode in error pages.
- [Fix] Fix incorrect names in some of the tables headers.
- [Fix] Normalize position of commanding buttons in regards to other UI elements.
- [Fix] Fix incorrect indentation of some of the info messages.
- [Fix] Fix tables headers inconsistent alignments.
- [Fix] Fix incorrect warning box header color in the dark mode.
- [Fix] Fix missing breadcrumbs on the consumers overview page.
- [Fix] Fix a case where disabled buttons would be enabled back too early.
- [Fix] The recent page breadcrumbs and offset id are not refreshed on change.
- [Fix] Direct URL access with too big partition causes librdkafka crash.
- [Fix] Fix incorrect breadcrumbs for pending consumer jobs.
- [Fix] Allow for using default search matchers in Karafka Web UI topics including Errors.
- [Fix] Ensure that when flashes or alerts are visible, pages are not auto-refreshed (would cause them to dissapear).
- [Fix] Time selector in the explorer does not disappear after clicking out.
- [Fix] Tombstone message presentation epoch doesn't make sense.
- [Fix] Fix incorrectly displayed "No jobs" alert info.
- [Fix] Previous / next navigation in the explorer does not work when moving to transactional checkpoints.
- [Fix] Errors explorer does not work with transactional produced data.
- [Fix] Errors explorer in OSS does not have pagination.
- [Maintenance] Require `karafka-core` `>= 2.4.8` and `karafka` `>= 2.4.16`.
- [Maintenance] Update `AirDatepicker` to `3.6.0`.

## 0.10.4 (2024-11-26)
- **[Breaking]** Drop Ruby `3.0` support according to the EOL schedule.
- [Enhancement] Extract producers tracking `sync_threshold` into an internal config.
- [Enhancement] Support complex Pro license loading strategies (Pro).
- [Enhancement] Change default `retention.ms` for the metrics topic to support Redpanda Cloud defaults (#450).
- [Enhancement] Include subscription group id in the consumers error tracking metadata.
- [Enhancement] Collect metadata details of low level client errors when error tracking.
- [Enhancement] Collect metadata details of low level listener errors when error tracking.
- [Fix] Toggle menu button post-turbo refresh stops working.

## 0.10.3 (2024-09-17)
- **[Feature]** Introduce ability to brand Web UI with environment (Pro).
- [Enhancement] Provide assignment status in the routing (Pro).
- [Enhancement] Support schedule cancellation via Web UI.
- [Enhancement] Rename "probing" to "tracing" to better reflect what this commanding option does.
- [Fix] Fix not working primary and secondary alert styles.

## 0.10.2 (2024-09-03)
- **[Feature]** Support Future Messages management (Pro).
- [Enhancement] Do not live-reload when form active.
- [Fix] Undefined method `deep_merge` for an instance of Hash.
- [Fix] Prevent live-polling on elements wrapped in a button.
- [Fix] Fix errors extractor failure on first message-less tick / eofed

## 0.10.1 (2024-08-23)
- **[Feature]** Support Recurring Tasks management (Pro).
- [Enhancement] Optimize command buttons so they occupy less space.
- [Enhancement] Improve tables headers capitalization.
- [Enhancement] Prevent live-polling when user hovers over actionable links to mitigate race conditions.
- [Fix] Fix partial lack of tables hover in daily mode.
- [Fix] Fix lack of tables hover in dark mode.
- [Fix] Normalize various tables types styling.
- [Fix] Fix ranges selectors position on wide screens.

## 0.10.0 (2024-08-19)
- **[Breaking]** Rename and reorganize visibility filter to policies engine since it is not only about visibility.
- **[Feature]** Replace Bootstrap with with tailwind + DaisyUI.
- **[Feature]** Redesign the UI and move navigation to the left to make space for future features.
- **[Feature]** Support per request policies for inspection and operations limitation.
- **[Feature]** Provide Search capabilities in the Explorer (Pro).
- **[Feature]** Provide dark mode.
- [Enhancement] Set `enable.partition.eof` to `false` for Web UI consumer group as it is not needed.
- [Enhancement] Allow for configuration of extra `kafka` scope options for the Web UI consumer group.
- [Enhancement] Support Karafka `#eofed` consumer action.
- [Enhancement] Provide topics watermarks inspection page (Pro).
- [Enhancement] Use Turbo to improve usability.
- [Enhancement] Round poll age reporting to precision of 2 reducing the payload size.
- [Enhancement] Round utilization reporting to precision of 2 reducing the payload size.
- [Enhancement] Validate states materialization lag in the status view.
- [Enhancement] Promote topics data pace to OSS.
- [Enhancement] Rename and normalize dashboard tabs.
- [Enhancement] Enable live data polling on the first visit so it does not have to be enabled manually.
- [Enhancement] Allow disabling ability to republish messages via policies.
- [Enhancement] Display raw numerical timestamp alongside message time.
- [Enhancement] Support `/topics` root redirect.
- [Enhancement] Prevent explorer from displaying too big payloads (bigger than 1MB by default)
- [Enhancement] Include deserialization object allocation stats.
- [Enhancement] Improve how charts with many topics work.
- [Enhancement] Count and display executed jobs independently from processed batches.
- [Enhancement] Prevent karafka-web from being configured before karafka is configured.
- [Enhancement] Use `ostruct` from RubyGems in testing.
- [Enhancement] Indicate in the status reporting whether Karafka is OSS or Pro.
- [Enhancement] Ship JS and CSS assets using Brotli and Gzip when possible.
- [Enhancement] Introduce a `/ux` page to ease with styling improvements and components management.
- [Enhancement] disallow usage of `<script>` blocks to prevent XSS.
- [Enhancement] Display full subscription group information in the Routing view, including injectable defaults.
- [Enhancement] Report Karafka consumer server execution mode.
- [Enhancement] Expose `sync_threshold` consumer tracking config to allow aligning of error-intense applications.
- [Refactor] Optimize subscription group data tracking flow.
- [Refactor] Namespace migrations so migrations related to each topic data are in an independent directory.
- [Refactor] Use errors for deny flow so request denials can occur from the inspection layer.
- [Maintenance] Require `karafka` `2.4.7` due to fixes and API changes.
- [Fix] Disallow quiet and stop commands for swarm workers.
- [Fix] Disallow quiet and stop commands for embedded workers.
- [Fix] Fix invalid deserialization metadata display in the per-message Explorer view.
- [Fix] Fix a case where started page refresh would update content despite limiters being in place.
- [Fix] Ruby 3.4.0 preview1 - No such file or directory.
- [Fix] Fix the live poll button state flickering when disabled.
- [Fix] Pace computation does not compensate for partial data reported.
- [Fix] DLQ parent topics get classified as DLQ in the Web.
- [Fix] Add missing space in the attempt label.
- [Fix] Fix lack of highlight of "Consumers" navigation when in the "Commands" tab.
- [Fix] Fix not working page reporting in breadcrumbs.
- [Fix] Fix invalid redirect when trying to view particular errors partition time location.
- [Fix] Fix several UI inconsistencies.
- [Fix] License identifier `LGPL-3.0` is deprecated for SPDX (#2177).
- [Fix] Do not include prettifying the payload for visibility in the resource computation cost.

## 0.9.1 (2024-05-03)
- [Fix] OSS `lag_stored` for not-subscribed consumers causes Web UI to crash.

## 0.9.0 (2024-04-26)
- **[Breaking]** Drop Ruby `2.7` support.
- **[Feature]** Provide ability to stop and quiet running consumers (Pro).
- **[Feature]** Provide ability to probe (get backtraces) of any running consumer (Pro).
- **[Feature]** Provide cluster lags in Health (Pro).
- **[Feature]** Provide ability to inspect cluster nodes configuration (Pro).
- **[Feature]** Provide ability to inspect cluster topics configuration (Pro).
- **[Feature]** Provide messages distribution graph statistics for topics (Pro).
- [Enhancement] Provide first offset in the OSS jobs tab.
- [Enhancement] Support failover for custom deserialization of headers and key in the explorer (Pro).
- [Enhancement] Support failover for custom deserialization of headers and key in the explorer (Pro).
- [Enhancement] Limit length of `key` presented in the list view of the explorer.
- [Enhancement] Improve responsiveness on big screens by increasing max width.
- [Enhancement] Auto-qualify topics with dlq/dead_letter case insensitive name components to DLQ view.
- [Enhancement] Make tables responsive.
- [Enhancement] Provide page titles for ease of navigation.
- [Change] Rename Cluster => Topics to Cluster => Replication to better align with what is shows.
- [Change] Make support messages more entertaining.
- [Change] Rename `processing.consumer_group` to `admin.group_id` for consistency with Karafka.
- [Refactor] Normalize what is process name and process id.
- [Refactor] Create one `pro/` namespace for all Web related sub-modules.
- [Refactor] Extract alerts into a common component.
- [Refactor] Generalize charts generation.
- [Fix] Fix invalid return when paginating with offsets.
- [Fix] Improve responsiveness of summary in the consumers view for lower resolutions.
- [Fix] Align pages titles format.
- [Fix] Fix missing link from lag counter to Health.
- [Fix] Fix a case where on mobile charts would not load correctly.
- [Fix] Fix cases where long consumer names would break UI.
- [Fix] Explorer deserializer wrongly selected for pattern matched topics.
- [Fix] Fix 404 error page invalid recommendation of `install` instead of `migrate`.
- [Fix] Fix dangling `console.log`.
- [Fix] Fix a case where consumer assignments would not be truncated on the consumers view.

## 0.8.2 (2024-02-16)
- [Enhancement] Defer scheduler background thread creation until needed allowing for forks.
- [Enhancement] Tag forks with fork indication + ppid reference when operating in swarm.
- [Fix] Fix issue where Health tabs would not be visible when no data reported.
- [Fix] Stopped processes subscriptions lacks indicator of no groups.
- [Fix] Terminated process state not supported in the web ui.
- [Fix] Rebalance reason can be empty on a SG when no network.

## 0.8.1 (2024-02-01)
- [Enhancement] Introduce "Lags" health view.
- [Enhancement] Remove "Stored Lag" and "Committed Offset" from Health Overview due to Lags Tab.
- [Enhancement] Report lag on consumers that did not yet marked offsets.
- [Enhancement] Use more accurate lag reporting that compensates for lack of stored lag.
- [Fix] When first message after process start is crashed without DLQ lag is not reported.
- [Fix] Wrong order of enabled injection causes fresh install to crash.

## 0.8.0 (2024-01-26)
- **[Feature]** Provide ability to sort table data for part of the views (note: not all attributes can be sorted due to technical limitations of sub-components fetching from Kafka).
- **[Feature]** Track and report pause timeouts via "Changes" view in Health.
- **[Feature]** Introduce pending jobs visibility alongside of running jobs both in total and per process.
- **[Feature]** Introduce states migrations for seamless upgrades.
- **[Feature]** Introduce "Data transfers" chart with data received and data sent to the cluster.
- **[Feature]** Introduce ability to download raw payloads.
- **[Feature]** Introduce ability to download deserialized message payload as JSON.
- [Enhancement] Support reporting of standby and active listeners for connection multiplexed subscription groups.
- [Enhancement] Support Periodic Jobs reporting.
- [Enhancement] Support multiplexed subscription groups.
- [Enhancement] Split cluster info into two tabs, one for brokers and one for topics with partitions.
- [Enhancement] Track pending jobs. Pending jobs are jobs that are not yet scheduled for execution by advanced schedulers.
- [Enhancement] Rename "Enqueued" to "Pending" to support jobs that are not yet enqueued but within a scheduler.
- [Enhancement] Make sure only running jobs are displayed in running jobs
- [Enhancement] Improve jobs related breadcrumbs
- [Enhancement] Display errors backtraces in OSS.
- [Enhancement] Display concurrency graph in OSS.
- [Enhancement] Support time ranges for graphs in OSS.
- [Enhancement] Report last poll time for each subscription group.
- [Enhancement] Show last poll time per consumer instance.
- [Enhancement] Display number of jobs in a particular process jobs view.
- [Enhancement] Promote "Batches" chart to OSS.
- [Enhancement] Promote "Utilization" chart to OSS.
- [Enhancement] Allow for explicit disabling of the Web UI tracking.
- [Fix] Web UI will keep reporting status even when not activated as long as required and in routes.
- [Fix] Fix times precisions that could be incorrectly reported by 1 second in few places.
- [Fix] Fix random order in Consumers groups Health view.
- [Change] Rename "Busy" to "Running" to align with "Running Jobs".
- [Change] Rename "Active subscriptions" to "Subscriptions" as process subscriptions are always active.
- [Maintenance] Introduce granular subscription group contracts.

## 0.7.10 (2023-10-31)
- [Fix] Max LSO chart does not work as expected (#201)

## 0.7.9 (2023-10-25)
- [Enhancement] Allow for `Karafka::Web.producer` reconfiguration from the default (`Karafka.producer`).
- [Change] Rely on `karafka-core` `>=` `2.2.4` to support lazy loaded custom web producer.

## 0.7.8 (2023-10-24)
- [Enhancement] Support transactional producer usage with Web UI.
- [Fix] Prevent a scenario where an ongoing transactional producer would have stats emitted and an error that could not have been dispatched because of the transaction, creating a dead-lock.
- [Fix] Make sure that the `recent` displays the most recent non-compacted, non-system message.
- [Fix] Improve the `recent` message display to compensate for aborted transactions.
- [Fix] Fix `ReferenceError: response is not defined` that occurs when Web UI returns refresh non 200.

## 0.7.7 (2023-10-20)
- [Fix] Remove `thor` as a CLI engine due to breaking changes.

## 0.7.6 (2023-10-10)
- [Fix] Fix nested SASL/SAML data visible in the routing details (#173)

## 0.7.5 (2023-09-29)
- [Enhancement] Update order of topics creation for the setup of Web to support zero-downtime setup of Web in running Karafka projects.
- [Enhancement] Add space delimiter to counters numbers to make them look better.
- [Improvement] Normalize per-process job tables and health tables structure (topic name on top).
- [Fix] Fix a case where charts aggregated data would not include all topics.
- [Fix] Make sure, that most recent per partition data for Health is never overwritten by an old state from a previous partition owner.
- [Fix] Cache assets for 1 year instead of 7 days.
- [Fix] Remove source maps pointing to non-existing locations.
- [Maintenance] Include license and copyrights notice for `timeago.js` that was missing in the JS min file. 
- [Refactor] Rename `ui.show_internal_topics` to `ui.visibility.internal_topics_display`

## 0.7.4 (2023-09-19)
- [Improvement] Skip aggregations on older schemas during upgrades. This only skips process-reports (that are going to be rolled) on the 5s window in case of an upgrade that should not be a rolling one anyhow. This simplifies the operations and minimizes the risk on breaking upgrades.
- [Fix] Fix not working `ps` for macOS.

## 0.7.3 (2023-09-18)
- [Improvement] Mitigate a case where a race-condition during upgrade would crash data.

## 0.7.2 (2023-09-18) 
- [Improvement] Display hidden by accident errors for OSS metrics.
- [Improvement] Use a five second cache for non-production environments to improve dev experience.
- [Improvement] Limit number of partitions listed on the Consumers view if they exceed 10 to improve readability and indicate, that there are more in OSS similar to Pro.
- [Improvement] Squash processes reports based on the key instead of payload skipping deserialization for duplicated reports.
- [Improvement] Make sure, that the Karafka topics present data can be deserialized and report on the status page if not.
- [Fix] Extensive data-poll on processes despite no processes being available.

## 0.7.1 (2023-09-15)
- [Improvement] Limit number of partitions listed on the Consumers view if they exceed 10 to improve readability and indicate, that there are more in Pro.
- [Improvement] Make sure, that small messages size (less than 100 bytes) is correctly displayed.
- [Fix] Validate refresh time.
- [Fix] Fix invalid message payload size display (KB instead of B, etc).

## 0.7.0 (2023-09-14)
- **[Feature]** Introduce graphs.
- **[Feature]** Introduce historical metrics storage.
- **[Feature]** Introduce per-topic data exploration in the Explorer.
- **[Feature]** Introduce per-topic and per-partition most recent message view with live reload.
- **[Feature]** Introduce a new per-process inspection view called "Details" ti display all process real-time aggregated data.
- **[Feature]** Introduce `bundle exec karafka-web migrate` that can be used to bootstrap the proper topics and initial data in environments where Karafka Web-UI should be used but is missing the initial setup.
- **[Feature]** Replace `decrypt` with a pluggable API for deciding which topics data to display.
- **[Feature]** Make sure, that the karafka server process that is materializing UI states is not processing any data having unsupported (newer) schemas. This state will be also visible in the status page.
- **[Feature]** Provide ability to reproduce a given message to the same topic partition with all the details from the per message explorer view.
- **[Feature]** Provide "surrounding" navigation link that allows to view the given message in the context of its surrounding. Useful for debugging of failures where the batch context may be relevant.
- **[Feature]** Allow for time based lookups per topic partition.
- **[Feature]** Introduce Offsets Health inspection view for frozen LSO lookups with `lso_threshold` configuration option.
- [Improvement] Support pattern subscriptions details in the routing view both by displaying the pattern as well as expanded routing details.
- [Improvement] Collect total number of threads per process for the process details view.
- [Improvement] Normalize naming of metrics to better reflect what they do (in reports and in the Web UI).
- [Improvement] Link error reported first and last offset to the explorer.
- [Improvement] Expand routing details to compensate for nested values in declarative topics.
- [Improvement] Include last rebalance age in the health view per consumer group.
- [Improvement] Provide previous / next navigation when viewing particular messages in the explorer.
- [Improvement] Provide previous / next navigation when viewing particular errors.
- [Improvement] Link all explorable offsets to the explorer.
- [Improvement] Extend status page checks to ensure, that it detects a case when Web-UI is not part of `karafka.rb` but still referenced in routes.
- [Improvement] Extend status page checks to ensure, that it detects a case where there is no initial consumers metrics in Kafka topic.
- [Improvement] Report Rails version when viewing status page (if Rails used).
- [Improvement] List Web UI topics names on the status page in the info section.
- [Improvement] Start versioning the materialized states schemas.
- [Improvement] Drastically improve the consumers view performance.
- [Improvement] Ship versioned assets to prevent invalid assets loading due to cache.
- [Improvement] Use `Cache-Control` to cache all the static assets.
- [Improvement] Link `counters` counter to jobs page.
- [Improvement] Include a sticky footer with the most important links and copyrights.
- [Improvement] Store lag in counters for performance improvement and historical metrics.
- [Improvement] Introduce in-memory cluster state cached to improve performance.
- [Improvement] Switch to offset based pagination instead of per-page pagination.
- [Improvement] Avoid double-reading of watermark offsets for explorer and errors display.
- [Improvement] When no params needed for a page, do not include empty params.
- [Improvement] Do not include page when page is 1 in the url.
- [Improvement] Align descriptions for the status page, to reflect that state check happens for consumers initial state.
- [Improvement] Report bytesize of raw payload when viewing message in the explorer.
- [Improvement] Use zlib compression for Karafka Web UI topics reports (all). Reduces space needed from 50 to 91%.
- [Improvement] Rename lag to lag stored in counters to reflect what it does.
- [Improvement] Collect both stored lag and lag.
- [Improvement] Introduce states and metrics schema validation.
- [Improvement] Prevent locking in sampler for time of OS data aggregation.
- [Improvement] Collect and report number of messages in particular jobs.
- [Improvement] Limit segment size for Web topics to ensure, that Web-UI does not drain resources.
- [Improvement] Introduce cookie based sessions management for future usage.
- [Improvement] Introduce config validation.
- [Improvement] Provide flash messages support.
- [Improvement] Use replication factor of two by default (if not overridden) for Web UI topics when there is more than one broker.
- [Improvement] Show a warning when replication factor of 1 is used for Web UI topics in production.
- [Improvement] Collect extra additional metrics useful for hanging transactions detection.
- [Improvement] Reorganize how the Health view looks.
- [Improvement] Hide all private Kafka topics by default in the explorer. Configurable with `show_internal_topics` config setting.
- [Fix] Return 402 status instead of 500 on Pro features that are not available in OSS.
- [Fix] Fix a case where errors would not be visible without Rails due to the `String#first` usage.
- [Fix] Fix a case where live-poll would be disabled but would still update data.
- [Fix] Fix a case where states materializing consumer would update state too often.
- [Fix] Fix a bug when rapid non-initialized shutdown could mess up the metrics.
- [Fix] Fix a case where upon multiple rebalances, part of the states materialization could be lost.
- [Fix] Make sure, that the flushing interval computation division happens with float.
- [Fix] Fix a case where app client id change could force web-ui to recompute the metrics.
- [Fix] Make sure, that when re-using same Karafka Web-UI topics as a different up, all states and reports are not recomputed back.
- [Fix] Fix headers size inconsistency between Health and Routing.
- [Fix] Fix invalid padding on status page.
- [Fix] Fix a case where root mounted Karafka Web-UI would not work.
- [Fix] Fix a case where upon hitting a too high page of consumers we would inform that no consumers are reporting instead of information that this page does not contain any reporting.
- [Refactor] Limit usage of UI models for data intense computation to speed up states materialization under load.
- [Refactor] Reorganize pagination engine to support offset based pagination.
- [Refactor] Use Roda `custom_block_results` plugin for controllers results handling.
- [Maintenance] Require `karafka` `2.2.0` due to fixes in the Iterator API and routing API extensions.

## 0.6.3 (2023-07-22)
- [Fix] Remove files from 0.7.0 accidentally added to the release.

## 0.6.2 (2023-07-22)
- [Fix] Fix extensive CPU usage when using HPET clock instead of TSC due to interrupt frequency.

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

## 0.3.1 (2023-03-27)
- [Fix] Add missing retention policy for states topic.
- [Fix] Fix display of compacted messages placeholders for offsets lower than low watermark.
- [Fix] Fix invalid pagination per page count.

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
