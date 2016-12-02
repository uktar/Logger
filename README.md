# Logger

## Getting Started

Download sources and copy Logger.swift to the target project.

## Usage

LogLevel: all, debug, info, warn, error, fatal, and off

``` swift
let log = Logger(level: LogLevel.debug, name: "test")

log.debug("This is a debug message.")
log.info("This is a info message.")
log.warn("This is a warn message.")
log.error("This is a error message.")

```

