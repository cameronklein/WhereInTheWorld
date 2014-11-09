
import Swift

extension String {
  func hash(size: Int) -> Int {
    var total = 0
    var scalars = self.unicodeScalars
    for scalar in scalars{
      total = total + Int(scalar.value)
    }
    total = total * countElements(self)
    let returnValue = total % size
    return returnValue
  }
}






class LinkedList : Printable {
  
  class Node {
    
    var next : Node?
    var value : String
    
    init(value: String){
      self.value = value
    }
    
  }
  
  var first : Node?
  var description : String {
    
    if first == nil {
      return "---"
    } else if first!.next == nil {
      return "\(first!.value)"
    } else {
      var number = 1
      var array = "\(first!.value)"
      var node = first
      while node!.next != nil{
        array = array + " -> " + node!.next!.value
        number += 1
        node = node!.next
      }
      return "\(array)"
    }
    
  }
  
  func addObject(value: String) {
    if first == nil {
      first = Node(value: value)
    } else if first!.next == nil {
      first!.next = Node(value: value)
    } else {
      var node = first
      while node!.next != nil{
        node = node!.next
      }
      node!.next = Node(value: value)
    }
  }
  
  func addObjectToFirst(value: String) {
    var temp: Node?
    if first == nil {
      first = Node(value: value)
    } else {
      temp = first
      first = Node(value: value)
      first!.next = temp
    }
  }
  
  func findObject(value : String) -> Node? {
    if first == nil {
      return nil
    }
    
    if first?.value == value {
      return first
    }
    
    var node = first
    while node!.next != nil {
      node = node!.next
      if node!.value == value {
        return node
      }
    }
    return nil
  }
  
  func removeObject(value: String) -> String? {
    
    if first == nil {
      return nil
    }
    
    if first!.value == value {
      let value = first!.value
      first = first!.next
      return value
    }
    
    var previousNode : Node?
    var node = first
    while node!.next != nil {
      previousNode = node
      node = node!.next
      if node!.value == value {
        let value = node!.value
        previousNode!.next = node!.next
        return value
      }
    }
    return nil
  }
  
}








class HashTable : Printable {

  var array = [LinkedList]()
  var size = 100
  var usedSize = 0
  var usedThreshold : Double {
    return Double(size) * 0.7
  }
  
  var description : String {
    var string = ""
    for list in array {
      string = string + list.description + "\n"
    }
    return string
  }
  
  init() {
    self.populateWithLinkedLists()
  }
  
  private func populateWithLinkedLists(){
    for i in 0...size {
      array.append(LinkedList())
    }
  }
  
  func findHash(object: String) -> Int{
    let index = object.hash(size)
    println(index)
    return index
  }

  func addObject(object: String) {
    array[findHash(object)].addObject(object)
    if Double(usedSize) > usedThreshold {
      resizeTable()
    }
  }
  
  func findObject(object: String) {
    array[findHash(object)].findObject(object)
  }
  
  func removeObject(object: String) {
    array[findHash(object)].removeObject(object)
  }
  
  func resizeTable(){
    let tempList = LinkedList()
    for list in array {
      while list.first != nil {
        tempList.addObject(list.removeObject(list.first!.value)!)
      }
    }
    self.size = self.size * 2
    populateWithLinkedLists()
    while tempList.first != nil {
      self.addObject(tempList.removeObject(tempList.first!.value)!)
    }
  }
}

class Stack {
  
  var list = LinkedList()
  
  func push(object: String){
    list.addObjectToFirst(object)
  }

  func peek() -> String? {
    return list.first?.value
  }
  
  func pop() -> String? {
    if list.first != nil {
      return list.removeObject(list.first!.value)
    } else {
      return nil
    }
  }
}




class Queue {
  
  var list = LinkedList()
  
  func enqueue(object : String) {
    list.addObject(object)
  }
  
  func dequeue() -> String? {
    if let node = list.first {
      return list.removeObject(node.value)
    } else {
      return nil
    }
  }
}

var stack = Stack()
stack.push("Hello")
stack.push("World")
stack.push("Today")
stack.pop()
stack.pop()
stack.pop()
stack.pop()

var queue = Queue()
queue.enqueue("Hello")
queue.enqueue("World")
queue.enqueue("Today")
queue.dequeue()
queue.dequeue()
queue.dequeue()
queue.dequeue()

var hashTable = HashTable()
hashTable.addObject("Hello")
hashTable.description
hashTable.addObject("World")
hashTable.addObject("Pasta")
hashTable.addObject("Potato")
hashTable.addObject("Franklin")
hashTable.addObject("Dog")
hashTable.addObject("Spaceship")
hashTable.addObject("Fart")
println(hashTable.description)
hashTable.removeObject("Hello")
println(hashTable.description)
