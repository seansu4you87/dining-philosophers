require 'thread'

# Our very own Actor implementation!
module Star
  module ClassMethods
    def new(*args, &block)
      Base.new(super)
    end
  end

  class << self
    def included(klass)
      klass.extend ClassMethods
    end

    def current
      Thread.current[:star]
    end
  end

  class Base
    def initialize(original)
      @original = original
      @mailbox = Queue.new
      @mutex = Mutex.new
      @running = true

      @assistant = Assistant.new(self)
      @thread = Thread.new do
        Thread.current[:star] = self
        go_through_mail
      end
    end

    def later
      @assistant
    end

    def receive_mail(meth, *args)
      @mailbox << [meth, args]
    end

    def terminate
      @running = false
    end

    def method_missing(meth, *args)
      open_mail(meth, *args)
    end

    private

    def go_through_mail
      while @running
        meth, args = @mailbox.pop
        open_mail(meth, *args)
      end

    rescue Exception => e
      puts "Error while running star: #{e}"
    end

    def open_mail(meth, *args)
      # We only want the original object to be doing one thing at a time
      @mutex.synchronize do
        @original.public_send(meth, *args)
      end
    end
  end

  class Assistant
    def initialize(star)
      @star = star
    end

    def method_missing(meth, *args)
      @star.receive_mail(meth, *args)
    end
  end
end
