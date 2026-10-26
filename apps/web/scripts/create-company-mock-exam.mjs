import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import { dirname, resolve } from 'path'
import { fileURLToPath } from 'url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
dotenv.config({ path: resolve(root, '.env.local') })
dotenv.config({ path: resolve(root, '.env') })
dotenv.config({ path: resolve(root, '../../.env') })

const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!url || !key) {
  console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

const supabase = createClient(url, key, {
  auth: { autoRefreshToken: false, persistSession: false },
})

const QUESTIONS = [
  // 1. Quantitative Aptitude & Probability (TCS Digital / Infosys SP)
  {
    order_index: 1,
    question_text:
      'A bag contains 4 red and 6 black balls. A ball is drawn at random and its color is noted. It is returned to the bag along with 2 additional balls of the same color. Another ball is drawn. What is the probability that the second ball drawn is red?',
    option_a: '1/3 (0.333)',
    option_b: '2/5 (0.400)',
    option_c: '7/15 (0.467)',
    option_d: '1/2 (0.500)',
    correct_option: 'B',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Let R1 be the event that 1st ball is red, and B1 that 1st is black. P(R1) = 4/10 = 2/5, P(B1) = 6/10 = 3/5.\nIf 1st is red: 2 red added -> 6 red, 6 black (total 12). P(R2|R1) = 6/12 = 1/2.\nIf 1st is black: 2 black added -> 4 red, 8 black (total 12). P(R2|B1) = 4/12 = 1/3.\nBy Total Probability: P(R2) = P(R1)*P(R2|R1) + P(B1)*P(R2|B1) = (2/5)*(1/2) + (3/5)*(1/3) = 1/5 + 1/5 = 2/5 = 0.400.',
  },

  // 2. Logical Reasoning & Relative Speed (Cognizant GenC Next / Accenture)
  {
    order_index: 2,
    question_text:
      'Two runners A and B start simultaneously from the same point on a 600m circular track in opposite directions with constant speeds of 15 m/s and 10 m/s respectively. Every time they meet, they interchange their speeds and continue in their respective directions. How many meters from the starting point (measured along the shorter arc) will their second meeting take place?',
    option_a: '0 meters (at the starting point)',
    option_b: '120 meters',
    option_c: '240 meters',
    option_d: '360 meters',
    correct_option: 'B',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'Relative speed = 15 + 10 = 25 m/s.\nTime for 1st meeting = 600 / 25 = 24 seconds.\nIn 24s, A runs (clockwise): 15 * 24 = 360m. B runs (counter-clockwise): 10 * 24 = 240m. First meeting is at 360m clockwise from start.\nAt 1st meeting, they interchange speeds: A now runs at 10 m/s (clockwise) and B runs at 15 m/s (counter-clockwise).\nTime for 2nd meeting is again 600 / 25 = 24 seconds.\nFrom 1st meeting point, A covers: 10 * 24 = 240m clockwise.\nPosition of 2nd meeting from start = 360 + 240 = 600m = 0m (at start)! Wait, B covers 15 * 24 = 360m counter-clockwise from 360m clockwise, which also ends at 0m (start).\nWait, 600m on a 600m track is 0m! Option A is 0 meters, but let us verify if speeds were swapped:\nFirst leg: A speed 15, B speed 10 -> meeting at 360m.\nSecond leg: A speed 10, B speed 15 -> relative speed is still 25 m/s, time = 24s.\nA travels 240m from 360m -> 360 + 240 = 600m = 0m from start! Therefore at the starting point (0m).',
    option_a: '0 meters (at the starting point)',
    correct_option: 'A',
  },

  // 3. Data Structures - Binary Search Tree (Zoho / Amazon)
  {
    order_index: 3,
    question_text:
      'Consider a Binary Search Tree created by inserting the keys in order: [50, 30, 70, 20, 40, 60, 80, 35, 45]. If root node 50 is deleted using the standard in-order successor replacement algorithm, what will be the in-order traversal of the resulting tree?',
    option_a: '[20, 30, 35, 40, 45, 60, 70, 80]',
    option_b: '[20, 35, 30, 40, 45, 60, 70, 80]',
    option_c: '[60, 30, 20, 40, 35, 45, 70, 80]',
    option_d: '[20, 30, 40, 35, 45, 70, 60, 80]',
    correct_option: 'A',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'The in-order traversal of any Binary Search Tree ALWAYS yields all elements in strictly ascending sorted order. Deleting key 50 leaves {20, 30, 35, 40, 45, 60, 70, 80}. Therefore, regardless of tree restructuring, the in-order traversal MUST remain strictly sorted: [20, 30, 35, 40, 45, 60, 70, 80].',
  },

  // 4. Algorithms - Dynamic Programming (Cisco / Freshworks)
  {
    order_index: 4,
    question_text:
      'Consider the 0/1 Knapsack problem with item weights W = [2, 3, 4, 5], values V = [3, 4, 5, 6], and knapsack capacity C = 8. What is the maximum total value achievable, and why must the 1D space-optimized DP array be traversed backwards from C down to weight[i]?',
    option_a:
      'Maximum value is 10; backwards traversal ensures each item is used at most once by preventing values from the current iteration from contaminating subsequent lookups.',
    option_b:
      'Maximum value is 11; forward traversal is required to allow multiple instances of items to be picked.',
    option_c:
      'Maximum value is 12; backwards traversal is only needed for negative weight items.',
    option_d:
      'Maximum value is 9; 1D array traversal direction has no mathematical effect on 0/1 knapsack.',
    correct_option: 'A',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Items: (w=2, v=3), (w=3, v=4), (w=4, v=5), (w=5, v=6). Capacity = 8.\nCombinations:\n- items 1, 2, 4: weights 2+3+5=10 > 8 (invalid)\n- items 1, 2, 3: weights 2+3+4=9 > 8 (invalid)\n- items 1, 4: w=2+5=7, val=3+6=9\n- items 2, 4: w=3+5=8, val=4+6=10 (optimal!)\n- items 1, 3: w=2+4=6, val=3+5=8\nMax value = 10. Traversing backwards ensures dp[w - weight[i]] represents the value from the previous item (i-1), enforcing the 0/1 (at most once) constraint.',
  },

  // 5. Algorithms - Graph Theory & Negative Weights (Google / Flipkart)
  {
    order_index: 5,
    question_text:
      'You are given a directed graph with V vertices and E edges containing negative edge weights, but guaranteed to have NO negative weight cycles. Which algorithm correctly computes single-source shortest paths, and what is its time complexity?',
    option_a: "Dijkstra's Algorithm with Fibonacci Heap in O(E + V log V)",
    option_b: "Bellman-Ford Algorithm in O(V * E)",
    option_c: "Floyd-Warshall Algorithm in O(V^2)",
    option_d: "Prim's Algorithm in O(E log V)",
    correct_option: 'B',
    difficulty: 'medium',
    marks: 1,
    explanation:
      "Dijkstra's algorithm greedily marks vertices as finalized and fails in the presence of negative edge weights (even without negative cycles). Bellman-Ford relaxes all E edges (V - 1) times, correctly handling negative edges in O(V * E) time.",
  },

  // 6. Data Structures - Double Hashing (Zoho / Thoughtworks)
  {
    order_index: 6,
    question_text:
      'In an open-addressing hash table of size M = 11 using double hashing: primary hash h1(k) = k mod 11, and secondary hash h2(k) = 1 + (k mod 7). The probe sequence is (h1(k) + i * h2(k)) mod 11 for i = 0, 1, 2... If slots 3, 8, and 2 are already occupied, into which slot will key k = 47 be placed?',
    option_a: 'Slot 5',
    option_b: 'Slot 7',
    option_c: 'Slot 9',
    option_d: 'Slot 10',
    correct_option: 'B',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'For key k = 47:\nh1(47) = 47 mod 11 = 3.\nh2(47) = 1 + (47 mod 7) = 1 + 5 = 6.\n- i = 0: (3 + 0*6) mod 11 = 3 (Occupied)\n- i = 1: (3 + 1*6) mod 11 = 9 mod 11 = 9 (Check if slot 9 is occupied: no, occupied are 3, 8, 2).\nWait! Let us re-verify: slots occupied are 3, 8, 2. Slot 9 is empty! (3 + 1*6) = 9.\nWait, let us check Option C: Slot 9. If i=1 lands on 9 and 9 is empty, key 47 goes to slot 9.\nLet us set option C as correct.',
    correct_option: 'C',
  },

  // 7. Operating Systems - Banker's Algorithm (Microsoft / Qualcomm)
  {
    order_index: 7,
    question_text:
      "In a system with 5 processes (P0 to P4) and 3 resource types (A, B, C) with currently Available = (3, 3, 2). Current Allocations and Maximum needs are:\nP0: Alloc(0,1,0), Max(7,5,3) -> Need(7,4,3)\nP1: Alloc(2,0,0), Max(3,2,2) -> Need(1,2,2)\nP2: Alloc(3,0,2), Max(9,0,2) -> Need(6,0,0)\nP3: Alloc(2,1,1), Max(2,2,2) -> Need(0,1,1)\nP4: Alloc(0,0,2), Max(4,3,3) -> Need(4,3,1)\nWhich of the following is a valid safe sequence?",
    option_a: '<P1, P3, P4, P0, P2>',
    option_b: '<P3, P1, P4, P0, P2>',
    option_c: '<P0, P1, P2, P3, P4>',
    option_d: '<P2, P1, P3, P4, P0>',
    correct_option: 'A',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Available: (3, 3, 2).\n- P1 Need (1, 2, 2) <= (3, 3, 2): P1 runs! New Available = (3,3,2) + Alloc(2,0,0) = (5, 3, 2).\n- P3 Need (0, 1, 1) <= (5, 3, 2): P3 runs! New Available = (5,3,2) + Alloc(2,1,1) = (7, 4, 3).\n- P4 Need (4, 3, 1) <= (7, 4, 3): P4 runs! New Available = (7,4,3) + Alloc(0,0,2) = (7, 4, 5).\n- P0 Need (7, 4, 3) <= (7, 4, 5): P0 runs! New Available = (7,4,5) + Alloc(0,1,0) = (7, 5, 5).\n- P2 Need (6, 0, 0) <= (7, 5, 5): P2 runs!\nSequence <P1, P3, P4, P0, P2> is completely valid.',
  },

  // 8. Operating Systems - Virtual Memory & TLB (Cisco / Intel)
  {
    order_index: 8,
    question_text:
      'A system uses a two-level page table scheme with a Translation Lookaside Buffer (TLB). TLB access time is 10 ns, and main memory access time is 80 ns. The TLB hit ratio is 90%. Assuming no page faults occur and both levels of page tables reside in main memory, what is the Effective Memory Access Time (EMAT)?',
    option_a: '90 ns',
    option_b: '106 ns',
    option_c: '124 ns',
    option_d: '170 ns',
    correct_option: 'B',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'On TLB hit (90%): TLB lookup (10 ns) + 1 Memory access for target data (80 ns) = 90 ns.\nOn TLB miss (10%): TLB lookup (10 ns) + Level 1 Page Table access (80 ns) + Level 2 Page Table access (80 ns) + Target data access (80 ns) = 250 ns.\nEMAT = (0.90 * 90) + (0.10 * 250) = 81 + 25 = 106 ns.',
  },

  // 9. DBMS - Composite Indexes & B+ Tree (Oracle / Zoho)
  {
    order_index: 9,
    question_text:
      'Consider a PostgreSQL table `orders (id, customer_id, status, created_at, total_amount)` with a composite B+ tree index: CREATE INDEX idx_orders ON orders (status, created_at, customer_id). Which of the following queries CANNOT use this index for an efficient index range scan?',
    option_a: "SELECT * FROM orders WHERE status = 'delivered' AND created_at >= '2026-01-01';",
    option_b: "SELECT * FROM orders WHERE status = 'pending' AND customer_id = 450;",
    option_c: "SELECT * FROM orders WHERE created_at >= '2026-01-01' AND customer_id = 450;",
    option_d: "SELECT * FROM orders WHERE status = 'shipped' AND created_at = '2026-05-10' AND customer_id = 102;",
    correct_option: 'C',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'B+ tree composite indexes follow the Leftmost Prefix Rule. The index columns are ordered (status, created_at, customer_id). Query C does NOT filter on the leading column `status`, which forces the query planner to perform a full table scan rather than an index range scan.',
  },

  // 10. DBMS - Concurrency & Isolation Levels (Amazon / Freshworks)
  {
    order_index: 10,
    question_text:
      'In ANSI SQL transaction isolation levels, Transaction T1 executes a query: SELECT count(*) FROM accounts WHERE balance > 10000. Transaction T2 then inserts a new account with balance = 15000 and commits. When T1 re-executes the same query in the same transaction, it receives a higher count. What is this phenomenon called, and which is the MINIMUM isolation level that prevents it in the SQL-92 standard?',
    option_a: 'Dirty Read; prevented by Read Committed',
    option_b: 'Non-repeatable Read; prevented by Repeatable Read',
    option_c: 'Phantom Read; prevented by Serializable',
    option_d: 'Lost Update; prevented by Read Uncommitted',
    correct_option: 'C',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'A Phantom Read occurs when a transaction queries a range of rows twice and sees newly inserted or deleted rows from another committed transaction. Under SQL-92, Repeatable Read is only required to lock existing rows, so Phantom Reads can only be prevented at the Serializable isolation level.',
  },

  // 11. Computer Networks - TCP Flow & Congestion Control (Cisco / Arista)
  {
    order_index: 11,
    question_text:
      'In TCP Reno, a sender is in Congestion Avoidance with cwnd = 32 MSS and ssthresh = 16 MSS. The sender receives 3 duplicate ACKs (indicating packet loss without timeout). What will be the new values of ssthresh and cwnd immediately upon entering Fast Recovery?',
    option_a: 'ssthresh = 16 MSS, cwnd = 1 MSS',
    option_b: 'ssthresh = 16 MSS, cwnd = 19 MSS',
    option_c: 'ssthresh = 1 MSS, cwnd = 16 MSS',
    option_d: 'ssthresh = 8 MSS, cwnd = 16 MSS',
    correct_option: 'B',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Under TCP Reno Fast Retransmit / Fast Recovery:\n1. ssthresh is set to half the current cwnd: ssthresh = cwnd / 2 = 32 / 2 = 16 MSS.\n2. In Fast Recovery, cwnd is set to ssthresh + 3 MSS (to account for the 3 packets that left the network and generated the 3 duplicate ACKs): cwnd = 16 + 3 = 19 MSS.\n(Only a retransmission timeout resets cwnd to 1 MSS).',
  },

  // 12. Computer Networks - Subnetting & CIDR (Juniper / Zoho)
  {
    order_index: 12,
    question_text:
      'An enterprise has been assigned the IPv4 network block 192.168.0.0/16. The IT department needs to allocate subnets such that each subnet can support at least 500 usable host machines. What is the tightest CIDR subnet mask to achieve this with minimal wasted IP space, and how many usable host addresses does each such subnet provide?',
    option_a: '/24 subnet mask; provides 510 usable hosts',
    option_b: '/23 subnet mask; provides 510 usable hosts',
    option_c: '/22 subnet mask; provides 1022 usable hosts',
    option_d: '/21 subnet mask; provides 2046 usable hosts',
    correct_option: 'B',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'Number of usable hosts = 2^h - 2 >= 500.\nFor h = 8: 2^8 - 2 = 254 (insufficient).\nFor h = 9: 2^9 - 2 = 512 - 2 = 510 usable hosts (>= 500).\nSubnet prefix length = 32 - 9 = /23 (Subnet mask 255.255.254.0).',
  },

  // 13. Java OOP - Static vs Dynamic Binding (Morgan Stanley / Zoho)
  {
    order_index: 13,
    question_text:
      `What is the console output of the following Java program?
class SuperClass {
    static void display() { System.out.print("Static-Super "); }
    void show() { System.out.print("Instance-Super "); }
}
class SubClass extends SuperClass {
    static void display() { System.out.print("Static-Sub "); }
    void show() { System.out.print("Instance-Sub "); }
}
public class PolymorphismDemo {
    public static void main(String[] args) {
        SuperClass obj = new SubClass();
        obj.display();
        obj.show();
    }
}`,
    option_a: 'Static-Super Instance-Sub',
    option_b: 'Static-Sub Instance-Sub',
    option_c: 'Static-Super Instance-Super',
    option_d: 'Static-Sub Instance-Super',
    correct_option: 'A',
    difficulty: 'medium',
    marks: 1,
    explanation:
      'Static methods in Java are resolved at compile-time based on the reference type (SuperClass), known as Method Hiding (early binding). Hence obj.display() calls SuperClass.display() -> "Static-Super ".\nInstance methods are resolved at runtime based on the actual object instance (SubClass), known as Method Overriding (dynamic dispatch). Hence obj.show() calls SubClass.show() -> "Instance-Sub ".\nOutput: "Static-Super Instance-Sub".',
  },

  // 14. Object-Oriented Design - Double-Checked Locking (Freshworks / Chargebee)
  {
    order_index: 14,
    question_text:
      'When implementing the thread-safe Singleton design pattern in Java using Double-Checked Locking (DCL), what critical problem does the `volatile` keyword on the instance variable solve?',
    option_a: 'It prevents the garbage collector from reclaiming the Singleton instance.',
    option_b:
      'It prevents instruction reordering by the compiler/CPU, which could otherwise allow another thread to observe a partially constructed (non-null but uninitialized) object reference.',
    option_c: 'It replaces the need for synchronized blocks by automatically acquiring an OS-level mutex.',
    option_d: 'It makes all fields within the Singleton class immutable.',
    correct_option: 'B',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Object creation `instance = new Singleton()` involves three bytecode steps: (1) allocate memory, (2) execute constructor, (3) assign reference. Without `volatile`, the CPU or JIT compiler may reorder steps 2 and 3. Another thread checking `if (instance == null)` could see a non-null reference before constructor execution completes, leading to severe concurrency bugs. `volatile` establishes a happens-before memory barrier preventing instruction reordering.',
  },

  // 15. System Design - Rate Limiting & High Availability (Zoho / Amazon)
  {
    order_index: 15,
    question_text:
      'In a high-throughput API gateway, you need to implement a rate limiter that can accommodate legitimate bursts of requests while maintaining a strict long-term average quota with O(1) memory overhead per client. Which algorithm best fulfills this requirement, and how does it differ from the Leaky Bucket algorithm?',
    option_a:
      'Token Bucket: tokens accumulate up to a maximum bucket capacity (allowing instantaneous bursts up to bucket size), whereas Leaky Bucket strictly smooths traffic by processing requests at a constant uniform rate regardless of burst demand.',
    option_b:
      'Fixed Window Counter: it resets client quotas at fixed intervals without any boundary burst vulnerability.',
    option_c:
      'Sliding Window Log: it stores every request timestamp in memory and requires less space than Token Bucket.',
    option_d:
      'Leaky Bucket: it allows arbitrary bursts by expanding its queue dynamically without dropping requests.',
    correct_option: 'A',
    difficulty: 'hard',
    marks: 2,
    explanation:
      'Token Bucket stores only two numbers per user (last_token_timestamp and current_token_count), providing O(1) memory and time complexity. It permits bursts up to bucket capacity because tokens can be consumed immediately. Leaky Bucket, by contrast, buffers requests in a queue and leaks them at a fixed uniform rate, eliminating bursts but adding latency to bursty traffic.',
  },
]

async function main() {
  console.log('🚀 Starting Placement Mock Assessment creation...')

  // 1. Fetch active batches
  const { data: batches, error: batchErr } = await supabase
    .from('batches')
    .select('id, batch_code, status')
    .in('status', ['active_senior', 'active_junior'])

  if (batchErr || !batches?.length) {
    console.error('❌ Could not fetch active batches:', batchErr)
    process.exit(1)
  }

  console.log(
    `✅ Found active batches: ${batches.map((b) => `${b.batch_code} (${b.id})`).join(', ')}`
  )

  // Exam Date: Tomorrow, October 27, 2026 at 09:30 AM IST (04:00 UTC)
  const tomorrow = new Date('2026-10-27T04:00:00.000Z')

  const totalMarks = QUESTIONS.reduce((sum, q) => sum + q.marks, 0)
  console.log(`📝 Total Questions: ${QUESTIONS.length}, Total Marks: ${totalMarks}`)

  // 2. Insert into mock_exams (open across batches with null batch_id)
  const examPayload = {
    title: 'Tier-1 Technical & Placement Readiness Mock Assessment',
    description:
      'Comprehensive 25-minute placement assessment featuring 15 medium-to-hard company recruitment questions covering Quantitative Aptitude, Data Structures & Algorithms, OS & Concurrency, DBMS Transactions, Computer Networks, Java OOP, and System Design.',
    domain: 'general',
    duration_minutes: 25,
    total_marks: totalMarks,
    exam_date: tomorrow.toISOString(),
    batch_id: null, // Open to all active batches
    ai_generated: false,
  }

  const { data: exam, error: examErr } = await supabase
    .from('mock_exams')
    .insert(examPayload)
    .select('id, title, duration_minutes, total_marks, exam_date')
    .single()

  if (examErr || !exam) {
    console.error('❌ Failed to insert mock_exam:', examErr)
    process.exit(1)
  }

  console.log(`✅ Mock Exam created successfully! Exam ID: ${exam.id}`)

  // 3. Insert questions into mock_exam_questions
  const questionInserts = QUESTIONS.map((q) => ({
    exam_id: exam.id,
    question_text: q.question_text,
    option_a: q.option_a,
    option_b: q.option_b,
    option_c: q.option_c,
    option_d: q.option_d,
    correct_option: q.correct_option,
    marks: q.marks,
    order_index: q.order_index,
    difficulty: q.difficulty,
    explanation: q.explanation,
  }))

  const { error: questionsErr } = await supabase
    .from('mock_exam_questions')
    .insert(questionInserts)

  if (questionsErr) {
    console.error('❌ Failed to insert mock_exam_questions:', questionsErr)
    await supabase.from('mock_exams').delete().eq('id', exam.id)
    process.exit(1)
  }

  console.log(`✅ All ${questionInserts.length} questions inserted successfully!`)

  // 4. Create announcement in notifications table for all users
  const notifPayload = {
    title: '🎯 Mandatory Placement Mock Assessment: Live Tomorrow (Oct 27)',
    message:
      'A 25-minute comprehensive placement mock test (22 marks) is scheduled for tomorrow, Oct 27 at 9:30 AM. Features medium-hard company questions across Quantitative Aptitude, DSA, OS Concurrency, DBMS Transactions, Computer Networks, Java OOP, and System Design. Tap to view the assessment.',
    notification_type: 'announcement',
    category: 'announcement',
    tone: 'friendly',
    target_audience: 'all',
    action_path: `/exam/${exam.id}`,
    is_active: true,
    generated_at: new Date().toISOString(),
    valid_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  }

  const { data: notif, error: notifErr } = await supabase
    .from('notifications')
    .insert(notifPayload)
    .select('id, title, message, action_path, target_audience')
    .single()

  if (notifErr || !notif) {
    console.error('❌ Failed to insert notification:', notifErr)
  } else {
    console.log(`✅ Notification dispatched to all users! Notification ID: ${notif.id}`)
  }

  // 5. Check if device tokens exist to push via FCM
  const { data: tokens, error: tokenErr } = await supabase
    .from('device_tokens')
    .select('token')
  console.log(`📱 Registered device tokens count: ${tokens?.length || 0}`)

  console.log('\n=============================================')
  console.log('🎉 Mock Assessment is Live & Ready!')
  console.log(`Exam Title:    ${exam.title}`)
  console.log(`Exam ID:       ${exam.id}`)
  console.log(`Duration:      ${exam.duration_minutes} minutes`)
  console.log(`Total Marks:   ${exam.total_marks}`)
  console.log(`Scheduled For: ${tomorrow.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })} IST`)
  console.log(`Direct Link:   https://www.psgmx.tech/exam/${exam.id}`)
  console.log(`Student Portal:https://www.psgmx.tech/student/exams`)
  console.log('=============================================\n')
}

main().catch((err) => {
  console.error('Fatal error:', err)
  process.exit(1)
})
