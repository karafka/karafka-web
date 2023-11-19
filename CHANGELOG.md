# Karafka Web changelog

## 0.8.0 (Unreleased)
- **[Feature]** Introduce states migrations for seamless upgrades.
- **[Feature]** Introduce "Data transfers" chart with data received and data sent to the cluster.
- **[Feature]** Introduce ability to download raw payloads.
- **[Feature]** Introduce ability to download deserialized message payload as JSON.
- [Enhancement] Make sure only running jobs are displayed in running jobs
- [Enhancement] Improve jobs related breadcrumbs
- [Enhancement] Display errors backtraces in OSS.
- [Enhancement] Report last poll time for each subscription group.
- [Enhancement] Show last poll time per consumer instance.
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

### Upgrade Notes

**NO** rolling upgrade needed. Just configuration update.

1. If you are using `ui.visibility_filter` this option is now `ui.visibility.filter` (yes, only `.` difference).
2. If you are using a custom visibility filter, it requires now two extra methods: `#download?` and `#export?`. The default visibility filter allows both actions unless message is encrypted.
3. `ui.show_internal_topics` config option has been moved and renamed to `ui.visibility.internal_topics`.

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

### Upgrade Notes

This is a **major** release that brings many things to the table.

#### Configuration

Karafka Web UI now relies on Roda session management. Please configure the `ui.sessions.secret` key with a secret value string of at least 64 characters:

```ruby
# Configure it BEFORE enabling
Karafka::Web.setup do |config|
  # REPLACE THIS with your own value. You can use `SecureRandom.hex(64)` to generate it
  # You may want to set it per ENV
  config.ui.sessions.secret = 'REPLACE ME! b94b2215cc66371f2c34b7d0c0df1a010f83ca45 REPLACE ME!'
end

Karafka::Web.enable!
```

#### Deployment

Because of the reporting schema update and new web-ui topics introduction, it is recommended to:

0. Make sure you have upgraded to `0.6.3` before and that it was deployed. To all the environments you want to migrate to `0.7.0`.
1. Upgrade the codebase based on the below details.
2. **Stop** the consumer materializing Web-UI. Unless you are running a Web-UI dedicated consumer as recommended [here](https://karafka.io/docs/Web-UI-Development-vs-Production/), you will have to stop all the consumers. This is **crucial** because of schema changes. `karafka-web` `0.7.0` introduces the detection of schema changes, so this step should not be needed in the future.
3. Run a migration command: `bundle exec karafka-web migrate` that will create missing states and missing topics. You **need** to run it for each of the environments where you use Karafka Web UI.
4. Deploy **all** the Karafka consumer processes (`karafka server`).
5. Deploy the Web update to your web server and check that everything is OK by visiting the status page.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error, or offset-related data may not be displayed correctly.

#### Code and API changes

1. `bundle exec karafka-web install` is now a single-purpose command that should run **only** when installing the Web-UI for the first time.
2. For creating needed topics and states per environment and during upgrades, please use the newly introduced non-destructive `bundle exec karafka-web migrate`. It will assess changes required and will apply only those.
3. Is no longer`ui.decrypt` has been replaced with `ui.visibility_filter` API. This API by default also does not decrypt data. To change this behavior, please implement your visibility filter as presented in our documentation.
4. Karafka Web UI `0.7.0` introduces an in-memory topics cache for some views. This means that rapid topics changes (repartitions/new topics) may be visible up to 5 minutes after those changes.
3. `ui.decrypt` setting has been replaced with `ui.visibility_filter` API. This API by default also does not decrypt data. To change this behavior, please implement your visibility filter as presented in our documentation.
4. Karafka Web-UI `0.7.0` introduces an in-memory topics cache for some views. This means that rapid topics changes (repartitions/new topics) may be visible up to 5 minutes after those changes.
5. Karafka Web UI requires now a new topic called `karafka_consumers_metrics`. If you use strict topic creation and ACL policies, please make sure it exists and that Karafka can both read and write to it.

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

### Upgrade Notes

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

### Upgrade Notes

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

### Upgrade Notes

Because of the reporting schema change, it is recommended to:

- First, deploy **all** the Karafka consumer processes (`karafka server`)
- Deploy the Web update to your web server.

Please note that if you decide to use the updated Web UI with not updated consumers, you may hit a 500 error.

## 0.3.1 (2023-03-27)
- [Fix] Add missing retention policy for states topic.
- [Fix] Fix display of compacted messages placeholders for offsets lower than low watermark.
- [Fix] Fix invalid pagination per page count.

### Upgrade Notes

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

### Upgrade Notes

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
