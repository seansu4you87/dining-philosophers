require_relative '../lib/star'
require_relative '../lib/problem'

class Philosopher
  include Star

  def initialize(name)
    @name = name
  end

  # Switching to the actor model requires us to get rid of our more procedural
  # event loop in favor of a message-oriented approach using recursion.  The
  # call to think() eventually leads to a call to eat(), which in truns calls
  # back to think(), completing the loop.

  def dine(table, position, waiter)
    @waiter = waiter

    @left_chopstick = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)

    think
  end

  def think
    puts "#{@name} is thinking."
    sleep(rand)

    # Asynchronously notifies the waiter object that the philosopher is ready
    # to eat

    @waiter.later.request_to_eat(Star.current)
  end

  def eat
    take_chopsticks

    puts "#{@name} is eating."
    sleep(rand)

    drop_chopsticks

    # Asynchronously notifies the waiter that the philosopher has finished
    # eating

    @waiter.later.done_eating(Star.current)

    think
  end

  def take_chopsticks
    @left_chopstick.take
    @right_chopstick.take
  end

  def drop_chopsticks
    @left_chopstick.drop
    @right_chopstick.drop
  end

  # This code is necessary in order for Celluloid to shut down cleanly
  def finalize
    drop_chopsticks
  end
end

class Waiter
  include Star

  def initialize
    @eating = []
  end

  # because synchronized data access is ensured by the actor model, this code
  # is much more simple than its mutex-based counterpart.  However, this
  # approach requires two methods (one to start and one to stop the eating
  # process), where the previous approach used a single serve() method.

  def request_to_eat(philosopher)
    return if @eating.include?(philosopher)

    @eating << philosopher
    philosopher.later.eat
  end

  def done_eating(philosopher)
    @eating.delete(philosopher)
  end
end

names = %w{Leonardo Michaelangelo Raphael Donatello Splinter}

philosophers = names.map { |name| Philosopher.new(name) }

waiter = Waiter.new # no longer needs a "capacity" argument
table = Table.new(philosophers.size)

philosophers.each_with_index do |philosopher, i|
  # No longer manually created a thread, rely on later() to do that for us.
  philosopher.later.dine(table, i, waiter)
end

sleep
