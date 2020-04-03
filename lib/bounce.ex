defmodule Bounce do
  # :observer.start


  @doc """
  Waiting for incoming messages appear and print out the message with a number
  of total received messages.

  ## Examples

    iex> pid = spawn(Bounce, :report, [1])
    iex> send(pid, "Hello World")
    iex> Received 1: Hello World

  Sometimes, we need to find and contact a process, so that process need to be
  findable.

  ## Examples

    iex> pid = spawn(Bounce, :report, [1])
    iex> Process.register(pid, :bounce)
    iex> send(:bounce, "Hello World")
    iex> Received 1: Hello World
    iex> send(:bounce, "Really")
    iex> Received 2: Really
    iex> my_bounce = Process.whereis(:bounce)
    iex> #PID<0.xx.0>
    iex> Process.unregister(:bounce)
    iex> true
    iex> check_exists = Process.whereis(:bounce)
    iex> nil
    iex> send(my_bounce, "Still there")
    iex> Received 3: Still there
  """

  def report(count) do
    new_count = receive do
      msg -> IO.puts "Received #{count}: #{msg}"
      count + 1
    end

    report(new_count)
  end

  @doc """
  Now, we attach the PID of the current process into the message, so the receiver can
  know who has sent the message and reply back.

  Note that the flush() function uses to popped out the all messages in the current process,
  and the self() function uses to get the current process' PID

  ## Examples

    iex> pid = spawn(Bounce, :drop, [])
    iex> send(pid, {self(), :moon, 20})
    iex> flush()
    iex> {:moon, 20, 8.0}
  """

  def drop do
    receive do
      {from, planemo, distance} ->
        send(from, {planemo, distance, fall_velocity(planemo, distance)})
        drop()
    end
  end

  @doc """
  At this time, the example is getting more complexity, the mph_drop/1 function spawns a
  Bounce.drop/0 process when it is first set up, then stores the new process pid in drop_pid.

  Then receive clause relies on the call from the shell, that includes only two argument while
  Bounce.drop/0 process sends back a result with three.

  The routine looks like:
    1. The current shell/process send a message with two arguments to mph_drop process
    2. The receive clause in the mph_drop process regconize the message have 2 arguments.
       It send another message to drop process.
    3. The drop process receive the message and do the calculation itself.
    4. After the calculation, the drop process sends back a message to mph_drop with 3 arguments
    5. The receive clause in the mph_drop process know that is a message with 3 arguments and
       print out the results.

  ## Examples

    iex> pid = spawn(Bounce, :mph_drop, [])
    iex> send(pid, {:earth, 20})
    iex> On earth, a fall of 20 metters yields a velocity of 44.xxxxxx mph.


  Sometimes, messages might or might not have a well format, and also processes are fragile,
  we often want our code to know when another process has failed. In this example, if bad inputs
  halts Bounce.drop/0, it deson't make much sense to leave the Bounce.convert/1 process hanging
  around, since the remaining Bounce.convert/1 process is now useless, it would be better to halt
  when Bounce.drop/0 fails.

  By changing spawn/3 to spawn_link/3, we fixed the issue.

  Links are bidirectional, if we kill a process, other processes that linked will also vanish, it
  is the default behavior for linked Elixir processes.

  When a process fails, it sends an explanation, in the form of tuple, to other processes that are
  linked to it. The tuple contains the atom :EXIT, the PID of the failed process, and the error as
  a complex tuple. If a process is set to trap exists, through a call to
  `Process.flag(:trap_exit, true)` these error reports arrive as messages, rather than just kill
  the process.

  That means we can trap the error and setting up a new process
  """

  def mph_drop do
    # drop_pid = spawn(Bounce, :drop, [])
    Process.flag(:trap_exit, true)
    drop_pid = spawn_link(Bounce, :drop, [])
    convert(drop_pid)
  end

  def convert(drop_pid) do
    receive do
      {planemo, distance} ->
        send(drop_pid, {self(), planemo, distance})
        convert(drop_pid)

      {:EXIT, pid, reason} ->
        new_drop_id = spawn_link(Bounce, :drop, [])
        convert(new_drop_id)

      {planemo, distance, velocity} ->
        mph_velocity = 2.23693629 * velocity
        IO.write("On #{planemo}, a fall of #{distance} metters ")
        IO.puts("yields a velocity of #{mph_velocity} mph.")
        convert(drop_pid)
    end
  end

  # HELPERS
  defp fall_velocity(:earth, distance) when distance >= 0 do
    :math.sqrt(2 * 9.8 * distance)
  end

  defp fall_velocity(:moon, distance) when distance >= 0 do
    :math.sqrt(2 * 1.6 * distance)
  end

  defp fall_velocity(:mars, distance) when distance >= 0 do
    :math.sqrt(2 * 3.71 * distance)
  end
end
