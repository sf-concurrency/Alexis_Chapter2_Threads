/*:

 # Dining Philosophers
 ### "Threads and Locks", Page 17
 [@algal](github.com/algal)


 Dining Philosophers is, the book tells us, a classic concurrency problem, and
 it walks us through a few solutions using different kinds of locks.

 This is an implementation in Swift, of the first Java example, adapted
 for the differences in Cocoa threads. But tbh I'm
 not I'm not sure is objc_sync_enter/exit is implementing the same kind of
 locking as Java's `synchronized` keyword. Seems likely, if
 they're both relying on the same underlying OS construct of pthread
 recursive locks.

 Philosopher.init, does not enforce a global ordering, requiring
 each philosopher to try to lock the lower-numbered chopstick first,
 so this implementation should deadlock with enough time or with
 different parameters.

 */


import Foundation
import PlaygroundSupport

/**
 Represents a particular chopstick.

 This is immutable, but we're using a class so we can synchronize on it

 */
class Chopstick
{
  let id:Int8
  init(id:Int8) {
    self.id = id
  }
}

func randomIntervalUnderOneSecond() -> TimeInterval {
  let milliseconds = UInt(arc4random_uniform(UInt32(1_000)))
  return Double(milliseconds) / Double(1_000)
}

/**
 Ever philosopher runs on its own thread.

 It holds a left chopstick and a right chopstick
 */
class Philosopher : Thread
{
  private var left:Chopstick
  private var right:Chopstick
  private var thinkCount:Int = 0

  init(left:Chopstick,right:Chopstick) {
    self.left = left
    self.right = right

  }

  override func main()
  {
    print("Philosopher \(self) starting")
    /*
     Instead of running until stopped by an exception like
     java.lang.Thread, every Foundation.Thread object has a
     cancellation flag.
     */
    while !self.isCancelled {
      self.thinkCount += 1
      if self.thinkCount % 10 == 0 {
        print("Philosopher \(self) has thought \(self.thinkCount) times")
      }
      Thread.sleep(forTimeInterval: randomIntervalUnderOneSecond() )

      /*
       Which version of dining philosophers is this exactly??


       objc_sync_enter "allocates recursive pthread mutex associated with" the
       object, in this case the chopsticks. That is, a recursive mutex.

       Java `synchronized()` seems to use a reentrant lock.

       There are also non-reentrant, non-recursive locks.

       */
      objc_sync_enter(self.left)
      objc_sync_enter(self.right)
      Thread.sleep(forTimeInterval: randomIntervalUnderOneSecond() )
      objc_sync_exit(right)
      objc_sync_exit(left)
    }
    print("Philosopher \(self) finishing")

  }
}

func startDining()
{
  let chopsticks:[Chopstick] = (0..<5).map(Chopstick.init)

  let philosophers = (0..<5).map {
    return Philosopher(left: chopsticks[$0], right: chopsticks[($0 + 1) % 5])
  }

  for philosopher in philosophers {
    philosopher.start()
  }

  // allow it to run until deadlock
  /*
   for philosopher in philosophers {
   philosopher.cancel()
   }
   */
}


startDining()

// to run on the command line:
 RunLoop.current.run()

// to run in a playground:
PlaygroundPage.current.needsIndefiniteExecution


