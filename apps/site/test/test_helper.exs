ExUnit.start
Application.ensure_all_started(:bypass)
# Ensure tzdata is up to date
{:ok, _} = Application.ensure_all_started(:tzdata)
_ = Tzdata.ReleaseUpdater.poll_for_update()
