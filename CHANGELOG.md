# Karafka Web changelog

## 0.2.0 (Unreleased)
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
