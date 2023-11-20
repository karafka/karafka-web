# Karafka Web

[![Build Status](https://github.com/karafka/karafka-web/workflows/ci/badge.svg)](https://github.com/karafka/karafka-web/actions?query=workflow%3Aci)
[![Gem Version](https://badge.fury.io/rb/karafka-web.svg)](http://badge.fury.io/rb/karafka-web)
[![Join the chat at https://slack.karafka.io](https://raw.githubusercontent.com/karafka/misc/master/slack.svg)](https://slack.karafka.io)

Karafka Web UI is a user interface for the [Karafka framework](https://github.com/karafka/karafka). The Web UI provides a convenient way for developers to monitor and manage their Karafka-based applications, without the need to use the command line or third party software.

It allows for easy access to various metrics, such as the number of messages consumed, the number of errors, and the number of consumers operating. It also provides a way to view the different Kafka topics, consumers, and groups that are being used by the application.

> [!IMPORTANT]
> All of Karafka ecosystems components documentation, including the Web UI, can be found [here](https://karafka.io/docs/#web-ui).

## Getting started

Karafka Web UI documentation is part of the Karafka framework documentation and can be found [here](https://karafka.io/docs).

![karafka web ui dashboard](https://raw.githubusercontent.com/karafka/misc/master/printscreens/web-ui.png)

## Karafka Pro Enhanced Web UI

The Enhanced Web UI, aside from all the features from the OSS version, also offers additional features and capabilities not available in the free version, making it a better option for those looking for more robust monitoring and management capabilities for their Karafka applications. Some of the key benefits of the Enhanced Web UI version include the following:

- Real-time and historical processing and utilization metrics.
- Real-time topics lag awareness.
- Enhanced consumers utilization metrics providing much better insights into processes resources utilization.
- Consumer process inspection to quickly analyze the state of a given consuming process.
- Consumer jobs inspection to view currently running jobs on a per-process basis.
- Health dashboard containing general consumption overview information
- Data Explorer allowing for viewing and exploring the data produced to Kafka topics. It understands the routing table and can deserialize data before it is displayed.
- Enhanced error reporting allowing for backtrace inspection and providing multi-partition support.
- DLQ / Dead insights allowing to navigate through DLQ topics and messages that were dispatched to them.

Help me provide high-quality open-source software. Please see the Karafka [homepage](https://karafka.io) for more details.
