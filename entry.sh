#!/bin/bash

su postgres -c "psql -c \"create role exampler with login password 'password';\""
su postgres -c "psql -c \"create database example;\""
DATABASE_URL=postgres://exampler:password@localhost:5432/example npm start
