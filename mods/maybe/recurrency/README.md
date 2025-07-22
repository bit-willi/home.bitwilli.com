# Recurrency module for maybe

## Goal
The goal of this 'module' is to provide a way to automatically duplicate transaction specific tags.
The maybe project does not support this natively, so, this module is a workaround to achieve the same result.

## Usage
To use this module, just configure the tag.id, with your and run the sql against your database.

## How it works
The module will find all transactions that have the tag.id set, and then it will duplicate all the transactions.
All the properties will be copied, except by entried.date, which will be set to the same date, but one month later.
