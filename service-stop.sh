#!/bin/bash

fleetctl stop dcheck.service; fleetctl unload dcheck.service; fleetctl destroy dcheck.service
