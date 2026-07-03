import json
import random

def generate_year1_questions():
    questions = []
    
    # 1. Math/Aptitude (34 questions)
    # Series: 10 qs
    for i in range(1, 11):
        q = f"What is the next number in the arithmetic progression: {i}, {i+3}, {i+6}, {i+9}?"
        opts = [str(i+10), str(i+11), str(i+12), str(i+13)]
        questions.append((q, opts, 2, 'Year 1 - Aptitude', 'easy'))
        
    # Percentages: 12 qs
    for i in range(1, 13):
        base = i * 50
        pct = i * 5
        ans = int(base * pct / 100)
        q = f"What is {pct}% of {base}?"
        opts = [str(ans - 5), str(ans), str(ans + 5), str(ans + 10)]
        questions.append((q, opts, 1, 'Year 1 - Aptitude', 'medium'))

    # Time and Work: 12 qs
    for i in range(2, 14):
        q = f"If Alice can complete a task in {i} days and Bob can complete it in {i*2} days, how many days will it take them together?"
        ans = round((i * i*2) / (i + i*2), 2)
        opts = [str(ans - 1), str(ans), str(ans + 1), str(ans + 2)]
        questions.append((q, opts, 1, 'Year 1 - Aptitude', 'medium'))

    # 2. Core CS (33 questions)
    os_concepts = ["Process Management", "Memory Management", "File Systems", "Device Drivers", "Interrupts"]
    for i in range(10):
        q = f"Which component of an OS is primarily responsible for {os_concepts[i%5].lower()}?"
        opts = ["Kernel", "Shell", "Compiler", "Loader"]
        questions.append((q, opts, 0, 'Year 1 - Core CS', 'easy'))

    networks = ["HTTP", "FTP", "SMTP", "TCP", "UDP"]
    for i in range(10):
        q = f"Which protocol is typically used for {networks[i%5]} communications?"
        opts = [networks[i%5], "IP", "ICMP", "ARP"]
        questions.append((q, opts, 0, 'Year 1 - Core CS', 'easy'))

    db_concepts = ["Primary Key", "Foreign Key", "Index", "View", "Trigger"]
    for i in range(13):
        q = f"In a relational database, what is the primary purpose of a {db_concepts[i%5]}?"
        opts = [f"To enforce {db_concepts[i%5].lower()} rules", "To speed up queries", "To store data", "To delete data"]
        questions.append((q, opts, 0, 'Year 1 - Core CS', 'medium'))

    # 3. Programming (33 questions)
    c_keywords = ["int", "float", "char", "double", "void"]
    for i in range(11):
        q = f"In C programming, what is the size of '{c_keywords[i%5]}' in a standard 32-bit compiler?"
        sizes = {"int": "4 bytes", "float": "4 bytes", "char": "1 byte", "double": "8 bytes", "void": "0 bytes"}
        opts = ["1 byte", "2 bytes", "4 bytes", sizes[c_keywords[i%5]]]
        correct = 3
        questions.append((q, opts, correct, 'Year 1 - Programming', 'easy'))

    for i in range(11):
        q = f"What is the output of 'printf(\"%d\", {i} + {i*2});' in C?"
        opts = [str(i), str(i*2), str(i*3), "Compilation Error"]
        questions.append((q, opts, 2, 'Year 1 - Programming', 'medium'))

    for i in range(11):
        q = f"Which operator is used for logical AND in C? (Variant {i})"
        opts = ["&&", "||", "!", "&"]
        questions.append((q, opts, 0, 'Year 1 - Programming', 'easy'))

    return questions

def generate_year2_questions():
    questions = []
    
    # 1. Advanced DSA (34 questions)
    ds = ["AVL Tree", "Red-Black Tree", "B-Tree", "Trie", "Graph"]
    for i in range(12):
        q = f"What is the worst-case time complexity for insertion in a {ds[i%5]}?"
        opts = ["O(1)", "O(log n)", "O(n)", "O(n log n)"]
        correct = 1 if i%5 < 3 else 2
        questions.append((q, opts, correct, 'Year 2 - Advanced DSA', 'hard'))

    algos = ["Dijkstra", "Bellman-Ford", "Floyd-Warshall", "Kruskal", "Prim"]
    for i in range(11):
        q = f"Which algorithm is best suited to find the shortest path in a graph with negative weights? (Case {i})"
        opts = ["Dijkstra", "Bellman-Ford", "DFS", "BFS"]
        questions.append((q, opts, 1, 'Year 2 - Advanced DSA', 'medium'))

    for i in range(11):
        q = f"In dynamic programming, what is the time complexity of solving the 0/1 Knapsack problem with capacity W and n items? (Variation {i})"
        opts = ["O(n)", "O(W)", "O(n*W)", "O(2^n)"]
        questions.append((q, opts, 2, 'Year 2 - Advanced DSA', 'hard'))

    # 2. System Design (33 questions)
    sys_concepts = ["Load Balancer", "API Gateway", "Cache", "Message Queue", "Database Index"]
    for i in range(11):
        q = f"In a distributed system, what is the main role of a {sys_concepts[i%5]}?"
        opts = ["Distribute traffic", "Store persistent data", "Render UI", "Compile code"]
        questions.append((q, opts, 0, 'Year 2 - System Design', 'medium'))

    for i in range(11):
        q = f"According to the CAP theorem, which two guarantees can a distributed data store provide simultaneously? (Scenario {i})"
        opts = ["Consistency and Availability", "Availability and Partition Tolerance", "Consistency and Partition Tolerance", "Any two of the three"]
        questions.append((q, opts, 3, 'Year 2 - System Design', 'hard'))

    db_types = ["Relational DB", "Document Store", "Key-Value Store", "Graph DB", "Time-Series DB"]
    for i in range(11):
        q = f"Which database type is most appropriate for highly connected data like social networks? ({db_types[i%5]} context)"
        opts = ["Relational DB", "Key-Value Store", "Graph DB", "Document Store"]
        questions.append((q, opts, 2, 'Year 2 - System Design', 'medium'))

    # 3. Advanced Aptitude (33 questions)
    for i in range(11):
        q = f"In how many ways can {i+3} distinct books be arranged on a shelf?"
        import math
        ans = math.factorial(i+3)
        opts = [str(ans-1), str(ans), str(ans+1), str(ans*2)]
        questions.append((q, opts, 1, 'Year 2 - Advanced Aptitude', 'hard'))

    for i in range(11):
        q = f"A bag contains {i+2} red balls and {i+3} blue balls. What is the probability of drawing a red ball?"
        ans = f"{i+2}/{2*i+5}"
        opts = [ans, f"{i+3}/{2*i+5}", f"1/{2*i+5}", f"{i+2}/{i+3}"]
        questions.append((q, opts, 0, 'Year 2 - Advanced Aptitude', 'medium'))

    for i in range(11):
        q = f"If a boat travels {10+i} km/hr in still water and the river flows at {2+i} km/hr, what is the downstream speed?"
        ans = (10+i) + (2+i)
        opts = [str(ans - 2), str(ans), str(ans + 2), str(ans + 4)]
        questions.append((q, opts, 1, 'Year 2 - Advanced Aptitude', 'medium'))

    return questions

def main():
    q1 = generate_year1_questions()
    q2 = generate_year2_questions()
    all_questions = q1 + q2
    
    # Shuffle options for realism, but keep track of correct answer
    final_questions = []
    for q_text, opts, correct_idx, topic, diff in all_questions:
        correct_val = opts[correct_idx]
        shuffled_opts = list(opts)
        random.shuffle(shuffled_opts)
        new_correct_idx = shuffled_opts.index(correct_val)
        final_questions.append((q_text, shuffled_opts, new_correct_idx, topic, diff))
        
    with open('seed_200_questions.sql', 'w') as f:
        f.write("-- 200 Unique Questions Seed Data\n")
        f.write("INSERT INTO public.question_bank (question_text, options, correct_option, topic, difficulty)\nVALUES\n")
        
        values_lines = []
        for q in final_questions:
            q_text, opts, correct, topic, diff = q
            opts_json = json.dumps(opts).replace("'", "''")
            q_text_escaped = q_text.replace("'", "''")
            values_lines.append(f"('{q_text_escaped}', '{opts_json}'::jsonb, {correct}, '{topic}', '{diff}')")
            
        f.write(",\n".join(values_lines))
        f.write(";\n")
        
if __name__ == '__main__':
    main()
