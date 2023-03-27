# Karafka Web changelog

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
