# HeliumKit

[![CI Status](http://img.shields.io/travis/tanis2000/HeliumKit.svg?style=flat)](https://travis-ci.org/tanis2000/HeliumKit)
[![Version](https://img.shields.io/cocoapods/v/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)
[![License](https://img.shields.io/cocoapods/l/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)
[![Platform](https://img.shields.io/cocoapods/p/HeliumKit.svg?style=flat)](http://cocoadocs.org/docsets/HeliumKit)

## About

HeliumKit is a lightweight framework that sits between your web services and the business logic of your app.

**WARNING!** HelimKit is still in **alpha** version and API might change any time.

It provides basic mapping to automate conversion from DTO coming from your web services into object models of your business domain. We decided to streamline the process by adopting some libraries and frameworks:

- PromiseKit to manage all the async code
- FMDB to store data in SQLite
- Mantle to convert models to and from JSON representation
- MTLFMDBAdapter to convert models into SQL statements to feed to FMDB

The main focus is to keep this framework as lightweight as possible and at the same time make it flexible enough for you to craft the perfect solution to your data transfer and storage layer. Many ideas come from RestKit as I've been using that framework for commercial apps before. But I've never been fond of Core Data as the storage architecture. I'm way too used to good old SQL statements and I can't live with the threading issues that you have to fight against when using Core Data. Core Data is great, but it's not for me.

HeliumKit can simply keep your data in in-memory models or it can write them to SQLite as needed. That's completely configurable. I tried to keep in mind the convention over configuration paradigm as I hate boilerplate code.
I hope you find this framework just as useful as I do. Contributions and pull requests are welcome!

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

HeliumKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "HeliumKit"

## Author

Valerio Santinelli, santinelli@altralogica.it

## License

HeliumKit is available under the MIT license. See the LICENSE file for more info.

