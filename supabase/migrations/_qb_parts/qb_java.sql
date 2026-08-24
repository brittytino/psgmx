INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('Which of the following is NOT a valid identifier in Java?', '["_value","2ndValue","$amount","valueOf"]'::jsonb, 1, 'java', 'easy', true),
('Which access modifier restricts visibility to within the same class only?', '["public","protected","private","default (package-private)"]'::jsonb, 2, 'java', 'easy', true),
('What is the default value of a boolean instance variable in Java?', '["true","false","0","null"]'::jsonb, 1, 'java', 'easy', true),
('Which keyword is used to import a package in Java?', '["include","import","using","package"]'::jsonb, 1, 'java', 'easy', true),
('What is the correct file extension for compiled Java bytecode?', '[".java",".class",".jar",".exe"]'::jsonb, 1, 'java', 'easy', true),
('Which of these is a valid single-line comment in Java?', '["# comment","// comment","'' comment","<!-- comment -->"]'::jsonb, 1, 'java', 'easy', true),
('Which method is the entry point of a standalone Java application?', '["start()","init()","main()","run()"]'::jsonb, 2, 'java', 'easy', true),
('What does the final keyword do when applied to a variable?', '["Makes it static","Prevents reassignment after initialization","Makes it private","Makes it a constant that must be initialized to zero"]'::jsonb, 1, 'java', 'medium', true),
('Which operator is used to check equality of primitive values in Java?', '["=","==","===","equals"]'::jsonb, 1, 'java', 'easy', true),
('Which of the following is NOT a Java keyword?', '["goto","friend","transient","strictfp"]'::jsonb, 1, 'java', 'medium', true),
('What is the size of an int in Java?', '["16 bits","32 bits","64 bits","platform-dependent"]'::jsonb, 1, 'java', 'easy', true),
('Which statement about Java''s switch statement on Strings is true?', '["Not supported until Java 7","Uses reference equality internally","Cannot have a default case","Works only with String literals"]'::jsonb, 0, 'java', 'medium', true),
('Which loop is guaranteed to execute its body at least once?', '["for","while","do-while","enhanced for"]'::jsonb, 2, 'java', 'easy', true),
('What is the result of 5 / 2 in Java where both operands are int?', '["2.5","2","3","2.0"]'::jsonb, 1, 'java', 'medium', true),
('Which of these is used to explicitly convert a double to an int?', '["Automatic widening","Explicit narrowing cast","Autoboxing","instanceof"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

int x = 1;
System.out.println(1 + 2 + "3" + 4 + 5);', '["3345","15","1+2+3+4+5","33345"]'::jsonb, 0, 'java', 'hard', true),
('Which of the following correctly declares a constant in Java?', '["const int X = 5;","final int X = 5;","static X = 5;","readonly int X = 5;"]'::jsonb, 1, 'java', 'easy', true),
('Which of the following is a valid way to declare an array in Java?', '["int arr[] = new int[5];","int arr = new int(5);","array int arr[5];","int[5] arr;"]'::jsonb, 0, 'java', 'easy', true),
('What does the instanceof operator return?', '["The class name","A boolean indicating type compatibility","An integer type code","The object''s hashcode"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

int x = 10;
int y = x++ + ++x;
System.out.println(y);', '["20","21","22","23"]'::jsonb, 2, 'java', 'hard', true),
('Which of these is NOT a primitive data type in Java?', '["int","float","String","char"]'::jsonb, 2, 'java', 'easy', true),
('What is the default value of an int instance variable?', '["null","0","1","undefined"]'::jsonb, 1, 'java', 'easy', true),
('Which wrapper class is used to represent a primitive char?', '["Char","Character","CharWrapper","Chr"]'::jsonb, 1, 'java', 'medium', true),
('What is autoboxing in Java?', '["Converting a wrapper object to its primitive type automatically","Converting a primitive to its wrapper object automatically","Casting between primitive types","Boxing an array"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

Integer a = 127;
Integer b = 127;
System.out.println(a == b);', '["true","false","Compilation error","NullPointerException"]'::jsonb, 0, 'java', 'hard', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('What is the output of the following code?

Integer a = 200;
Integer b = 200;
System.out.println(a == b);', '["true","false","Compilation error","NullPointerException"]'::jsonb, 1, 'java', 'hard', true),
('Which of these ranges is correct for the byte primitive type?', '["-128 to 127","0 to 255","-32768 to 32767","-256 to 255"]'::jsonb, 0, 'java', 'medium', true),
('What happens when you unbox a null Integer to an int?', '["It becomes 0","It throws NullPointerException","It throws ClassCastException","Compilation error"]'::jsonb, 1, 'java', 'medium', true),
('Which primitive type is used to store true/false values?', '["bit","bool","boolean","flag"]'::jsonb, 2, 'java', 'easy', true),
('What is the default value of a double instance variable?', '["0","0.0","null","NaN"]'::jsonb, 1, 'java', 'medium', true),
('Which of the following is the correct wrapper class for int?', '["Int","Integer","IntWrapper","INT"]'::jsonb, 1, 'java', 'easy', true),
('How many bytes does a long occupy in Java?', '["4","8","2","16"]'::jsonb, 1, 'java', 'medium', true),
('Which method converts a String to an int primitive?', '["Integer.valueOf(String).toPrimitive()","Integer.parseInt(String)","Integer.toInt(String)","String.toInt()"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

byte b = 10;
b = b + 1;
System.out.println(b);', '["Prints 11","Compilation error","Runtime exception","Prints 10"]'::jsonb, 1, 'java', 'medium', true),
('What is the range of a char in Java?', '["0 to 65535","-128 to 127","-32768 to 32767","0 to 255"]'::jsonb, 0, 'java', 'easy', true),
('Which of these is true regarding wrapper classes in Java?', '["They are mutable","They are immutable","They can be subclassed","They store primitives by reference only"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

double d = 0.1 + 0.2;
System.out.println(d == 0.3);', '["true","false","Compilation error","1"]'::jsonb, 1, 'java', 'hard', true),
('Which combination is idiomatically used to declare a class-level constant in Java?', '["const","final","static final","readonly"]'::jsonb, 2, 'java', 'medium', true),
('What does Integer.MAX_VALUE represent?', '["2147483647","9223372036854775807","32767","4294967295"]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

short s = 32767;
s++;
System.out.println(s);', '["32768","-32768","0","Compilation error"]'::jsonb, 1, 'java', 'hard', true),
('Which keyword is used to inherit a class in Java?', '["implements","extends","inherits","super"]'::jsonb, 1, 'java', 'easy', true),
('Which keyword is used by a class to implement an interface?', '["extends","implements","inherits","uses"]'::jsonb, 1, 'java', 'easy', true),
('Can a Java class extend more than one class directly?', '["Yes, always","No, Java supports single inheritance for classes","Yes, but only with abstract classes","Yes, up to 3 classes"]'::jsonb, 1, 'java', 'medium', true),
('Which keyword is used to call a superclass constructor?', '["this()","super()","base()","parent()"]'::jsonb, 1, 'java', 'easy', true),
('What is method overriding in Java?', '["Defining multiple methods with the same name but different parameters in the same class","Redefining a superclass method in a subclass with the same signature","Declaring a method as static","Hiding a variable in a subclass"]'::jsonb, 1, 'java', 'medium', true),
('What is method overloading in Java?', '["Same method name with different parameter lists in the same class","Same method signature in parent and child class","Declaring a method final","Making a method private"]'::jsonb, 0, 'java', 'easy', true),
('Which of these cannot be instantiated directly?', '["A final class","A concrete class","An abstract class","A public class"]'::jsonb, 2, 'java', 'medium', true),
('Can an abstract class have a constructor?', '["No, never","Yes","Only if it has no abstract methods","Only static constructors"]'::jsonb, 1, 'java', 'easy', true),
('What happens if a subclass does not implement all abstract methods of its abstract superclass?', '["The compiler auto-implements them","The subclass must also be declared abstract","A runtime error occurs","It is allowed as long as the class is public"]'::jsonb, 1, 'java', 'hard', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('In Java, can an interface contain instance fields with mutable state?', '["Yes, freely","No, interface fields are implicitly public static final","Only private fields","Only protected fields"]'::jsonb, 1, 'java', 'medium', true),
('Since which Java version can interfaces have default methods with an implementation?', '["Java 5","Java 6","Java 7","Java 8"]'::jsonb, 3, 'java', 'medium', true),
('What is the output of the following code?

class A {
    void show() { System.out.println("A"); }
}
class B extends A {
    void show() { System.out.println("B"); }
}
public class Test {
    public static void main(String[] args) {
        A obj = new B();
        obj.show();
    }
}', '["A","B","Compilation error","AB"]'::jsonb, 1, 'java', 'hard', true),
('What is the output of the following code?

class A {
    static void show() { System.out.println("A"); }
}
class B extends A {
    static void show() { System.out.println("B"); }
}
public class Test {
    public static void main(String[] args) {
        A obj = new B();
        obj.show();
    }
}', '["A","B","Compilation error","Runtime exception"]'::jsonb, 0, 'java', 'hard', true),
('What is the term for a static method in a subclass with the same signature as one in the superclass?', '["Overriding","Overloading","Method hiding","Shadowing"]'::jsonb, 2, 'java', 'medium', true),
('Which keyword prevents a method from being overridden?', '["static","final","private","abstract"]'::jsonb, 1, 'java', 'easy', true),
('Can a private method be overridden in Java?', '["Yes, always","No, private methods are not inherited/visible for overriding","Only in the same package","Only if declared final"]'::jsonb, 1, 'java', 'medium', true),
('Which access modifier makes a class member accessible only within its own class and subclasses, even in different packages?', '["default","private","protected","public"]'::jsonb, 2, 'java', 'easy', true),
('What is polymorphism in the context of Java OOP?', '["Ability of an object to take many forms based on context","Ability to have multiple constructors","Hiding implementation details","Wrapping data and methods together"]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

interface Vehicle {
    default void start() { System.out.println("Vehicle starting"); }
}
class Car implements Vehicle {
    public void start() { System.out.println("Car starting"); }
}
public class Test {
    public static void main(String[] args) {
        Vehicle v = new Car();
        v.start();
    }
}', '["Vehicle starting","Car starting","Compilation error","Both printed"]'::jsonb, 1, 'java', 'hard', true),
('Which of the following is true about constructors in Java?', '["They must return void","They cannot be overloaded","They have the same name as the class and no return type","They must be public"]'::jsonb, 2, 'java', 'easy', true),
('Which keyword refers to the current object instance within a method?', '["self","this","current","obj"]'::jsonb, 1, 'java', 'easy', true),
('What is encapsulation in Java?', '["Bundling data and methods together and restricting direct access to data","Creating multiple classes","Using inheritance to reuse code","Overriding methods"]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

class Animal {
    Animal() { System.out.println("Animal constructor"); }
}
class Dog extends Animal {
    Dog() { System.out.println("Dog constructor"); }
}
public class Test {
    public static void main(String[] args) {
        new Dog();
    }
}', '["Dog constructor","Animal constructor","Animal constructor\nDog constructor","Dog constructor\nAnimal constructor"]'::jsonb, 2, 'java', 'hard', true),
('Can a Java interface extend multiple interfaces?', '["No, only one","Yes, an interface can extend multiple interfaces","Only up to two","No, interfaces cannot extend interfaces"]'::jsonb, 1, 'java', 'easy', true),
('Which of these is a valid abstract method declaration inside an abstract class?', '["abstract void run() { }","abstract void run();","void abstract run();","private abstract void run();"]'::jsonb, 1, 'java', 'easy', true),
('What is the purpose of the super keyword besides calling the parent constructor?', '["To access a hidden static field","To access parent class members overridden or hidden by the subclass","To create a new instance","To declare an abstract method"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

abstract class Shape {
    abstract double area();
    void display() { System.out.println("Area: " + area()); }
}
class Circle extends Shape {
    double r;
    Circle(double r) { this.r = r; }
    double area() { return Math.PI * r * r; }
}
public class Test {
    public static void main(String[] args) {
        Shape s = new Circle(2);
        s.display();
    }
}', '["Area: 12.566370614359172","Area: 12.56","Compilation error because Shape cannot have a display method","Area: 0.0"]'::jsonb, 0, 'java', 'hard', true),
('Which keyword is used to define an interface in Java?', '["class","interface","abstract","implements"]'::jsonb, 1, 'java', 'easy', true),
('What is true about static methods declared in interfaces (Java 8+)?', '["They can be overridden by implementing classes","They must be called using the interface name, and are not inherited by implementing classes","They cannot have a body","They are not allowed in interfaces"]'::jsonb, 1, 'java', 'hard', true),
('What is the output of the following code?

class Base {
    int x = 10;
}
class Derived extends Base {
    int x = 20;
}
public class Test {
    public static void main(String[] args) {
        Base obj = new Derived();
        System.out.println(obj.x);
    }
}', '["10","20","Compilation error","30"]'::jsonb, 0, 'java', 'hard', true),
('Which class is the superclass of all exceptions and errors in Java?', '["Exception","Throwable","RuntimeException","Error"]'::jsonb, 1, 'java', 'easy', true),
('Which of these is an unchecked exception?', '["IOException","SQLException","NullPointerException","ClassNotFoundException"]'::jsonb, 2, 'java', 'easy', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('Which of these is a checked exception?', '["ArithmeticException","IOException","ArrayIndexOutOfBoundsException","NullPointerException"]'::jsonb, 1, 'java', 'medium', true),
('Which block always executes regardless of whether an exception occurs?', '["catch","finally","try","throw"]'::jsonb, 1, 'java', 'easy', true),
('What is the correct syntax to handle multiple exception types in a single catch block (Java 7+)?', '["catch (IOException, SQLException e)","catch (IOException | SQLException e)","catch IOException, SQLException e","catch (IOException & SQLException e)"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

public class Test {
    static int test() {
        try {
            return 1;
        } finally {
            System.out.println("finally");
        }
    }
    public static void main(String[] args) {
        System.out.println(test());
    }
}', '["finally\n1","1\nfinally","1","finally"]'::jsonb, 0, 'java', 'hard', true),
('What is the output of the following code?

public class Test {
    static int test() {
        int x = 1;
        try {
            return x;
        } finally {
            x = 2;
        }
    }
    public static void main(String[] args) {
        System.out.println(test());
    }
}', '["1","2","Compilation error","0"]'::jsonb, 0, 'java', 'hard', true),
('What is try-with-resources used for in Java?', '["Automatically closing resources that implement AutoCloseable","Catching multiple exceptions","Retrying a block of code","Avoiding the use of catch blocks entirely"]'::jsonb, 0, 'java', 'medium', true),
('Which interface must a resource implement to be used in a try-with-resources statement?', '["Closeable only","AutoCloseable","Serializable","Cloneable"]'::jsonb, 1, 'java', 'medium', true),
('Which keyword is used to manually throw an exception in Java?', '["throw","throws","raise","catch"]'::jsonb, 0, 'java', 'easy', true),
('Which keyword is used in a method signature to declare that it might throw a checked exception?', '["throw","throws","catch","exception"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        try {
            int[] arr = new int[3];
            System.out.println(arr[5]);
        } catch (ArrayIndexOutOfBoundsException e) {
            System.out.println("Caught: " + e.getClass().getSimpleName());
        }
    }
}', '["Caught: ArrayIndexOutOfBoundsException","Caught: Exception","Compilation error","arr[5]"]'::jsonb, 0, 'java', 'hard', true),
('What happens if an exception is thrown inside a catch block and a finally block is present?', '["The finally block is skipped","The finally block still executes before the exception propagates","A compilation error occurs","The original exception is suppressed silently"]'::jsonb, 1, 'java', 'medium', true),
('In try-with-resources with multiple resources, in what order are they closed?', '["In the order they were declared","In reverse order of their declaration","Randomly","All simultaneously"]'::jsonb, 1, 'java', 'medium', true),
('Which of these is true about the Error class in Java, such as OutOfMemoryError?', '["It is meant to be caught and handled by application code routinely","It represents serious problems that applications typically should not try to catch","It is a checked exception","It extends RuntimeException"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        try {
            throw new RuntimeException("first");
        } catch (Exception e) {
            throw new RuntimeException("second");
        } finally {
            System.out.println("finally block");
        }
    }
}', '["finally block is printed, then the program terminates with an uncaught RuntimeException: second","Only \"second\" is printed, finally never runs","first is printed then second","Compilation error"]'::jsonb, 0, 'java', 'hard', true),
('Can a finally block contain a return statement that overrides the try block''s return value?', '["No, it is a compile-time error","Yes, and it will override the try/catch return value","Yes, but only for void methods","No, finally cannot alter control flow"]'::jsonb, 1, 'java', 'medium', true),
('Which of these best describes a custom exception class in Java?', '["A class that extends Thread","A user-defined class extending Exception or RuntimeException","A built-in Java exception","An interface for exceptions"]'::jsonb, 1, 'java', 'easy', true),
('What is exception chaining used for in Java?', '["To catch multiple exceptions at once","To preserve the original cause of an exception while throwing a new one","To close resources automatically","To retry failed operations"]'::jsonb, 1, 'java', 'medium', true),
('What does a NullPointerException typically indicate?', '["Division by zero","Attempting to use a reference that points to null","Array index out of bounds","Invalid number format"]'::jsonb, 1, 'java', 'easy', true),
('Which interface does ArrayList implement to allow duplicate elements in insertion order?', '["Set","List","Map","Queue"]'::jsonb, 1, 'java', 'easy', true),
('Which collection does NOT allow duplicate elements?', '["ArrayList","LinkedList","HashSet","Vector"]'::jsonb, 2, 'java', 'easy', true),
('Which Map implementation maintains the insertion order of its keys?', '["HashMap","TreeMap","LinkedHashMap","Hashtable"]'::jsonb, 2, 'java', 'medium', true),
('Which Map implementation keeps keys sorted according to their natural ordering?', '["HashMap","LinkedHashMap","TreeMap","Hashtable"]'::jsonb, 2, 'java', 'medium', true),
('Which of these is a key-value pair collection in Java?', '["List","Set","Map","Queue"]'::jsonb, 2, 'java', 'easy', true),
('What is the key difference between ArrayList and LinkedList?', '["ArrayList uses a doubly linked list; LinkedList uses a dynamic array","ArrayList uses a dynamic array with fast random access; LinkedList uses a doubly linked list with fast insertions/deletions","They are functionally identical","LinkedList cannot store null values"]'::jsonb, 1, 'java', 'medium', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('Which of these collections is synchronized (thread-safe) by default?', '["ArrayList","HashMap","Vector","HashSet"]'::jsonb, 2, 'java', 'medium', true),
('What is the output of the following code?

import java.util.*;
public class Test {
    public static void main(String[] args) {
        List<String> list = new ArrayList<>();
        list.add("A");
        list.add("B");
        list.add("C");
        for (String s : list) {
            if (s.equals("B")) {
                list.remove(s);
            }
        }
        System.out.println(list);
    }
}', '["[A, C]","[A, B, C]","Throws ConcurrentModificationException at runtime","Compilation error"]'::jsonb, 2, 'java', 'hard', true),
('Which interface represents a collection that does not allow duplicate elements?', '["List","Set","Queue","Map"]'::jsonb, 1, 'java', 'easy', true),
('What must be overridden together for correct behavior of custom objects used as HashMap keys?', '["compareTo() and toString()","equals() and hashCode()","clone() and equals()","toString() and hashCode()"]'::jsonb, 1, 'java', 'medium', true),
('Which of these classes represents a First-In-First-Out (FIFO) structure in the Java Collections Framework?', '["Stack","Queue","Set","Map"]'::jsonb, 1, 'java', 'easy', true),
('What does HashSet use internally to store its elements?', '["An ArrayList","A LinkedList","A HashMap instance","A TreeMap instance"]'::jsonb, 2, 'java', 'medium', true),
('What is the output of the following code?

import java.util.*;
public class Test {
    public static void main(String[] args) {
        Set<Integer> set = new TreeSet<>();
        set.add(5);
        set.add(1);
        set.add(3);
        set.add(1);
        System.out.println(set);
    }
}', '["[1, 3, 5]","[5, 1, 3]","[1, 1, 3, 5]","[5, 3, 1]"]'::jsonb, 0, 'java', 'hard', true),
('Which Java Collections class provides static utility methods like sort() and reverse() for lists?', '["Arrays","Collections","List","Comparator"]'::jsonb, 1, 'java', 'medium', true),
('Which interface must a class implement to allow custom sorting order via compareTo()?', '["Comparator","Comparable","Serializable","Iterable"]'::jsonb, 1, 'java', 'easy', true),
('What is the difference between Comparable and Comparator in Java?', '["Comparable defines external sorting logic; Comparator defines natural ordering within the class","Comparable defines natural ordering within the class via compareTo(); Comparator defines external sorting logic via compare()","They are identical interfaces","Comparator can only be used with primitives"]'::jsonb, 1, 'java', 'hard', true),
('Which of these Map implementations allows both a null key and multiple null values?', '["Hashtable","TreeMap","HashMap","ConcurrentHashMap"]'::jsonb, 2, 'java', 'easy', true),
('Why does Hashtable not allow null keys or values while HashMap does?', '["Hashtable is a legacy synchronized class with stricter null-handling design; HashMap explicitly permits one null key and multiple null values","There is no difference between them","HashMap does not allow nulls either","Hashtable allows nulls but HashMap does not"]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

import java.util.*;
public class Test {
    public static void main(String[] args) {
        Map<String, Integer> map = new HashMap<>();
        map.put("a", 1);
        map.put("b", 2);
        map.put("a", 3);
        System.out.println(map.get("a"));
    }
}', '["1","2","3","null"]'::jsonb, 2, 'java', 'hard', true),
('Which collection class would you use to implement a Last-In-First-Out (LIFO) structure?', '["Queue","Stack (or Deque)","List","Set"]'::jsonb, 1, 'java', 'medium', true),
('What does the Iterator interface''s hasNext() method do?', '["Removes the current element","Returns true if there are more elements to iterate","Moves to the previous element","Sorts the collection"]'::jsonb, 1, 'java', 'easy', true),
('What exception can occur if you call remove() on a List directly while iterating it with a for-each loop, instead of using the Iterator''s remove()?', '["NoSuchElementException","ConcurrentModificationException","UnsupportedOperationException","IndexOutOfBoundsException"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

import java.util.*;
public class Test {
    public static void main(String[] args) {
        List<Integer> list = Arrays.asList(1, 2, 3);
        list.set(0, 100);
        System.out.println(list);
    }
}', '["[100, 2, 3]","UnsupportedOperationException thrown","[1, 2, 3]","Compilation error"]'::jsonb, 0, 'java', 'hard', true),
('Which of these interfaces represents the root interface of the Java Collections Framework hierarchy, excluding Map?', '["List","Collection","Set","Iterable"]'::jsonb, 1, 'java', 'easy', true),
('What is the time complexity of retrieving an element by index from an ArrayList?', '["O(1)","O(n)","O(log n)","O(n log n)"]'::jsonb, 0, 'java', 'medium', true),
('What is the time complexity of inserting an element at the beginning of a LinkedList?', '["O(1)","O(n)","O(log n)","O(n^2)"]'::jsonb, 0, 'java', 'medium', true),
('Which class would you use for a synchronized, growable array-like list from the legacy Collections API?', '["ArrayList","Vector","LinkedList","HashSet"]'::jsonb, 1, 'java', 'easy', true),
('What does List.of("a", "b") return in Java 9+?', '["A mutable ArrayList","An immutable list that throws UnsupportedOperationException on modification","A LinkedList","A synchronized list"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

import java.util.*;
public class Test {
    public static void main(String[] args) {
        Deque<Integer> stack = new ArrayDeque<>();
        stack.push(1);
        stack.push(2);
        stack.push(3);
        System.out.println(stack.pop());
        System.out.println(stack.peek());
    }
}', '["3\n2","1\n2","3\n1","1\n3"]'::jsonb, 0, 'java', 'hard', true),
('Which collection type in Java allows fast lookups but does not maintain any order of elements?', '["LinkedHashSet","TreeSet","HashSet","ArrayList"]'::jsonb, 2, 'java', 'easy', true),
('Which two common ways exist to create a thread in Java?', '["Extending the Thread class or implementing the Runnable interface","Only extending the Thread class","Only implementing Runnable","Using the Fork class"]'::jsonb, 0, 'java', 'easy', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('Which method starts the execution of a new thread, invoking its run() method in a new call stack?', '["run()","start()","execute()","begin()"]'::jsonb, 1, 'java', 'easy', true),
('What happens if you call run() directly instead of start() on a Thread object?', '["A new thread is created and run() executes on it","run() executes on the calling thread itself; no new thread is created","It throws IllegalThreadStateException","Compilation error"]'::jsonb, 1, 'java', 'medium', true),
('What does the synchronized keyword ensure in Java?', '["That a method runs faster","That only one thread can execute the synchronized block/method on a given object at a time","That a variable is thread-local","That a thread never blocks"]'::jsonb, 1, 'java', 'medium', true),
('What is a deadlock in the context of multithreading?', '["When a thread completes execution too quickly","When two or more threads are blocked forever, each waiting for the other to release a resource","When a thread throws an exception","When garbage collection pauses a thread"]'::jsonb, 1, 'java', 'medium', true),
('Which keyword indicates that a variable''s value may be modified by multiple threads and should always be read from main memory?', '["transient","volatile","synchronized","static"]'::jsonb, 1, 'java', 'easy', true),
('What is the purpose of the wait() method in Java?', '["To pause the current thread and release the lock until notified","To permanently stop a thread","To create a new thread","To increase thread priority"]'::jsonb, 0, 'java', 'medium', true),
('Which method wakes up a single thread that is waiting on an object''s monitor?', '["wait()","notify()","notifyAll()","resume()"]'::jsonb, 1, 'java', 'medium', true),
('What are the typical states of a Java thread''s lifecycle?', '["New, Runnable, Blocked/Waiting, Timed Waiting, Terminated","Start, Stop, Pause","On, Off","Created, Deleted"]'::jsonb, 0, 'java', 'easy', true),
('Why is Runnable often preferred over extending Thread directly?', '["Runnable executes faster","Since Java supports single inheritance, implementing Runnable leaves the class free to extend another class","Thread is deprecated","Runnable objects use less memory"]'::jsonb, 1, 'java', 'medium', true),
('What does Java guarantee about the following code?

public class Test {
    public static void main(String[] args) throws InterruptedException {
        Runnable r = () -> System.out.println(Thread.currentThread().getName());
        Thread t1 = new Thread(r, "T1");
        Thread t2 = new Thread(r, "T2");
        t1.start();
        t2.start();
    }
}', '["T1 always prints before T2","T2 always prints before T1","The order between T1 and T2 output is not guaranteed","The program throws an exception"]'::jsonb, 2, 'java', 'hard', true),
('What is a thread pool used for?', '["To create unlimited threads for every task","To reuse a fixed set of worker threads for executing tasks efficiently","To pause all threads","To replace the JVM''s garbage collector"]'::jsonb, 1, 'java', 'medium', true),
('Which interface''s single abstract method is run()?', '["Thread","Runnable","Callable","Executor"]'::jsonb, 1, 'java', 'easy', true),
('What is the key difference between the Runnable and Callable interfaces?', '["Callable can return a result and throw checked exceptions; Runnable cannot return a result","Runnable can return a result; Callable cannot","They are identical","Callable is only for single-threaded programs"]'::jsonb, 0, 'java', 'hard', true),
('Which class in java.util.concurrent is commonly used to manage a pool of threads?', '["ThreadGroup","ExecutorService","ThreadLocal","Semaphore"]'::jsonb, 1, 'java', 'easy', true),
('Which JVM memory area stores objects created with the new keyword?', '["Stack","Heap","Method Area","PC Register"]'::jsonb, 1, 'java', 'easy', true),
('Which JVM memory area stores method call frames including local variables and partial results?', '["Heap","Stack","Metaspace","Heap and Stack combined"]'::jsonb, 1, 'java', 'easy', true),
('What is the primary purpose of the Garbage Collector in the JVM?', '["To compile Java source code","To automatically reclaim memory occupied by objects no longer reachable","To manage thread synchronization","To load classes at runtime"]'::jsonb, 1, 'java', 'medium', true),
('In modern JVMs (Java 8+), where is class metadata stored, replacing the old PermGen space?', '["Heap","Metaspace (native memory)","Stack","Young Generation"]'::jsonb, 1, 'java', 'medium', true),
('What does JIT stand for in the context of the JVM?', '["Java Interface Type","Just-In-Time (compiler)","Java Internal Thread","Java Instance Table"]'::jsonb, 1, 'java', 'easy', true),
('Which component is responsible for loading .class files into the JVM at runtime?', '["Garbage Collector","Class Loader","JIT Compiler","Execution Engine"]'::jsonb, 1, 'java', 'medium', true),
('What is the Young Generation in the JVM heap primarily used for?', '["Storing long-lived objects","Storing newly created, short-lived objects","Storing static class metadata","Storing thread stacks"]'::jsonb, 1, 'java', 'medium', true),
('Which of these best describes the JVM?', '["A compiler that converts Java source to bytecode","An abstract computing machine that enables a computer to run Java bytecode","A version control tool","A build automation tool"]'::jsonb, 1, 'java', 'easy', true),
('What typically triggers a StackOverflowError in Java?', '["The heap runs out of memory","Excessive or infinite recursion exhausting the call stack","A missing catch block","An infinite loop with no method calls"]'::jsonb, 1, 'java', 'medium', true),
('What triggers an OutOfMemoryError: Java heap space?', '["Too many method calls","The JVM cannot allocate an object because the heap is full and cannot be expanded","A syntax error","A missing garbage collector"]'::jsonb, 1, 'java', 'medium', true),
('Can a Java program run on any operating system without recompilation, given a compatible JVM?', '["No, Java code must be recompiled per OS","Yes, this is the write once, run anywhere principle enabled by the JVM","Only on Windows","Only on Linux"]'::jsonb, 1, 'java', 'easy', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('What does "garbage" refer to in the context of garbage collection?', '["Objects that still have live references","Objects that are no longer reachable from any live thread or root reference","All objects on the heap","Static variables"]'::jsonb, 1, 'java', 'medium', true),
('Which generational garbage collection hypothesis states that most objects die young?', '["The weak generational hypothesis","The strong generational hypothesis","The heap locality hypothesis","The reference counting hypothesis"]'::jsonb, 1, 'java', 'hard', true),
('Which of the following is NOT one of the main JVM run-time data areas?', '["Heap","Method Area","Registry Editor","Java Stack"]'::jsonb, 2, 'java', 'easy', true),
('What is the role of the Execution Engine in the JVM?', '["It loads class files","It executes the bytecode instructions, either interpreting or JIT-compiling them","It manages garbage collection only","It handles network I/O"]'::jsonb, 1, 'java', 'medium', true),
('Why are String objects immutable in Java?', '["For performance reasons only","For security, thread-safety, and to enable the String pool for reuse","Because Java does not support mutable objects","Immutability is a JVM requirement for all classes"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

String a = "hello";
String b = "hello";
System.out.println(a == b);', '["true","false","Compilation error","NullPointerException"]'::jsonb, 0, 'java', 'hard', true),
('What is the output of the following code?

String a = new String("hello");
String b = "hello";
System.out.println(a == b);', '["true","false","Compilation error","NullPointerException"]'::jsonb, 1, 'java', 'hard', true),
('What does the String.intern() method do?', '["Converts a String to lowercase","Returns a canonical representation from the String pool, adding it if not already present","Deletes the String from memory","Compares two Strings for equality"]'::jsonb, 1, 'java', 'medium', true),
('Which method should be used to compare the actual content of two String objects, not their references?', '["==","equals()","hashCode()","compareTo() only"]'::jsonb, 1, 'java', 'easy', true),
('Why is String immutability useful when using Strings as HashMap keys?', '["Because immutable objects can''t be used as keys","Because their hashCode remains constant, ensuring reliable and safe hashing behavior","Because HashMap requires the key class to be final","It has no real benefit"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

String s = "Hello";
s.concat(" World");
System.out.println(s);', '["Hello","Hello World","Compilation error","World"]'::jsonb, 0, 'java', 'hard', true),
('Which class should be used for frequent string modifications to avoid creating many intermediate String objects?', '["String","StringBuilder","Character","StringPool"]'::jsonb, 1, 'java', 'medium', true),
('What is the key difference between StringBuilder and StringBuffer?', '["StringBuilder is synchronized (thread-safe); StringBuffer is not","StringBuffer is synchronized (thread-safe); StringBuilder is not","They are identical in every way","StringBuilder cannot be modified"]'::jsonb, 1, 'java', 'medium', true),
('Where are String literals typically stored by the JVM?', '["In the stack","In a special String pool area (part of heap memory)","In the PC register","On disk"]'::jsonb, 1, 'java', 'easy', true),
('What is the output of the following code?

String s1 = "Java";
String s2 = "Ja" + "va";
System.out.println(s1 == s2);', '["true","false","Compilation error","Depends on JVM implementation"]'::jsonb, 0, 'java', 'hard', true),
('What is the output of the following code?

String s1 = "Java";
String part = "Ja";
String s2 = part + "va";
System.out.println(s1 == s2);', '["true","false","Compilation error","NullPointerException"]'::jsonb, 1, 'java', 'hard', true),
('What does it mean for a class to be "immutable" in Java?', '["It has no methods","Its state cannot be changed after construction","It cannot be extended","It has only static fields"]'::jsonb, 1, 'java', 'medium', true),
('Which of these operations on a String returns a new String object rather than modifying the original?', '["toUpperCase()","All String methods that appear to modify content actually return new objects","length()","charAt()"]'::jsonb, 1, 'java', 'easy', true),
('How does String immutability contribute to thread safety?', '["It doesn''t; Strings are not thread-safe","Since the state cannot change after creation, multiple threads can safely share the same String instance without synchronization","Immutability forces single-threaded access","Strings use internal locks"]'::jsonb, 1, 'java', 'medium', true),
('Which keyword declares a member that belongs to the class rather than to any single instance?', '["final","static","instance","public"]'::jsonb, 1, 'java', 'easy', true),
('Can a static method access instance (non-static) variables directly?', '["Yes, always","No, static methods cannot directly access instance variables without an object reference","Only if declared final","Only in the constructor"]'::jsonb, 1, 'java', 'medium', true),
('What is the output of the following code?

class Counter {
    static int count = 0;
    Counter() { count++; }
}
public class Test {
    public static void main(String[] args) {
        new Counter();
        new Counter();
        new Counter();
        System.out.println(Counter.count);
    }
}', '["0","1","3","Compilation error"]'::jsonb, 2, 'java', 'hard', true),
('When are static initializer blocks executed in Java?', '["Every time an object is created","Once, when the class is first loaded into the JVM","Only when explicitly called","Never, unless main() calls them"]'::jsonb, 1, 'java', 'medium', true),
('Can static methods be overridden in the traditional polymorphic sense?', '["Yes, exactly like instance methods","No, they are hidden, not overridden","Yes, but only in the same package","Static methods cannot exist in subclasses"]'::jsonb, 1, 'java', 'easy', true),
('What is the correct way to access a static member from outside its declaring class?', '["Only through an object instance","Through the class name (ClassName.member) or an instance reference","It cannot be accessed from outside the class","Only through reflection"]'::jsonb, 1, 'java', 'easy', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('What is the output of the following code?

class Test {
    static { System.out.println("Static block"); }
    Test() { System.out.println("Constructor"); }
    public static void main(String[] args) {
        System.out.println("Main start");
        new Test();
    }
}', '["Static block\nMain start\nConstructor","Main start\nStatic block\nConstructor","Static block\nConstructor\nMain start","Main start\nConstructor\nStatic block"]'::jsonb, 0, 'java', 'hard', true),
('Can a static method be called without creating an instance of its class?', '["No, an instance is always required","Yes, static methods can be called directly via the class name","Only within the same class","Only if the class is abstract"]'::jsonb, 1, 'java', 'easy', true),
('What happens when you try to use the this keyword inside a static method?', '["It refers to the class itself","It compiles fine and refers to the calling instance","It causes a compile-time error since there is no instance context","It refers to null"]'::jsonb, 2, 'java', 'medium', true),
('What is a "static variable" also commonly known as?', '["Instance variable","Class variable","Local variable","Final variable"]'::jsonb, 1, 'java', 'easy', true),
('If a subclass does not override a static method, what happens when that method is called via a subclass reference?', '["Compilation error","The superclass''s static method is used, since it is inherited","It resolves to null","It always calls the most derived static method dynamically"]'::jsonb, 1, 'java', 'hard', true),
('What is the output of the following code?

class A {
    int x = 5;
    static int y = 10;
}
public class Test {
    public static void main(String[] args) {
        A obj1 = new A();
        A obj2 = new A();
        obj1.x = 100;
        obj1.y = 200;
        System.out.println(obj2.x + " " + obj2.y);
    }
}', '["5 200","100 200","5 10","100 10"]'::jsonb, 0, 'java', 'hard', true),
('Why can''t static methods be declared abstract in Java?', '["Static methods are resolved at compile-time with no dynamic dispatch, which conflicts with the deferred-implementation nature of abstract methods","There is no real reason, it is just a language quirk","Abstract methods must return values","Static and abstract mean the same thing"]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        int[] arr = {1, 2, 3};
        System.out.println(arr.length);
    }
}', '["3","2","Compilation error, should be length()","4"]'::jsonb, 0, 'java', 'medium', true),
('Which of these correctly gets the number of elements in a List?', '["list.length","list.length()","list.size()","list.count()"]'::jsonb, 2, 'java', 'easy', true);

INSERT INTO question_bank (question_text, options, correct_option, topic, difficulty, is_active) VALUES
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        String s1 = null;
        System.out.println("Value: " + s1);
    }
}', '["Value: null","NullPointerException thrown","Compilation error","Value: "]'::jsonb, 0, 'java', 'medium', true),
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        String s1 = null;
        System.out.println(s1.length());
    }
}', '["0","NullPointerException thrown at runtime","Compilation error","null"]'::jsonb, 1, 'java', 'hard', true),
('What is the output of the following code?

public class Test {
    public static void main(String[] args) {
        int a = 5;
        int b = 0;
        try {
            System.out.println(a / b);
        } catch (ArithmeticException e) {
            System.out.println("Cannot divide by zero");
        }
    }
}', '["Infinity","Cannot divide by zero","Compilation error","0"]'::jsonb, 1, 'java', 'medium', true);
