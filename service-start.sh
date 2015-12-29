#!/bin/bash

fleetctl submit ./dcheck.service && fleetctl start dcheck.service; fleetctl journal -follow=true -lines=50 dcheck
