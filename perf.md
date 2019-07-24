# Website Performance

### Problematic Calls

- `Schedules.Repo.by_route_ids`
- `Schedules.Repo.schedule_for_stop`

Called by:

- Schedule Page
  - called 1 time on Line page
  - called 1 time on Trip Info
- Schedule Finder (behind flag)
  - called 3 times
- Transit Near Me
  - called ~24 times on page load, ~10 times every 30 seconds

---

### Timed Calls

```
:timer.tc(fn ->
Schedules.Repo.by_route_ids(["743"], date: ~D[2019-08-30], direction_id: "0")
:ok
end)
852_283 -> 32_359
```

```
:timer.tc(fn ->
Schedules.Repo.schedule_for_stop("place-sstat", [date: "2019-07-24"])
:ok
end)
567_606 -> 13_056
```

```
:timer.tc(fn ->
  Schedules.Repo.schedule_for_stop("place-sstat", [date: "2019-07-24"])
  :ok
end)
3_159_269 -> 105_598

load_from_other_repos: 332_685 -> 105_149
trip: 15_103 -> 16_625 (called 1,634 times)
```

```
:timer.tc(fn ->
  Schedules.Repo.schedule_for_stop("place-sstat", [date: "2019-07-24"])
  :ok
end)

schedules api call: 3_290_559
parse schedules: 91_718
load_from_other_repos: 367_683
total: 3_750_863
```

### Improvements

- caching the final `Schedule` struct, not the schedule record
  - currently `load_from_other_repos` is called after the cache
- remove `Route`, `Stop`, `Trip` from `Schedule` struct
  - add `route_id`, `stop_id`, `trip_id` instead and sort this out downstream
- make `Trip` its own Repo
  - currently, if you are getting schedules, you are processing trips also
