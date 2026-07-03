// ============================================================
// PSGMX — supabase/types/database.types.ts
// Hand-written TypeScript interfaces matching the exact schema
// from 00_initial_schema.sql.
// Import in apps/web with: import type { Database } from '@/supabase/types/database.types'
// ============================================================

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

// ──────────────────────────────────────────────────────────────
// Enum-like string union types matching CHECK constraints
// ──────────────────────────────────────────────────────────────

export type BatchStatus = 'active_junior' | 'active_senior' | 'graduated'

export type UserRole = 'student' | 'alumni' | 'faculty' | 'hod'

export type AppRole = 'student' | 'team_leader' | 'coordinator' | 'placement_rep'

export type AttendanceStatus = 'present' | 'absent' | 'excused'

export type QuestionTopic =
  | 'aptitude'
  | 'verbal'
  | 'dsa'
  | 'dbms'
  | 'os'
  | 'networks'
  | 'oop'
  | 'python'
  | 'java'
  | 'hr_behavioral'

export type QuestionDifficulty = 'easy' | 'medium' | 'hard'

export type CorrectOption = 'a' | 'b' | 'c' | 'd'

export type SessionTargetScope = 'batch' | 'teams'

export type ArticleSource = 'web' | 'flutter_placement_log'

export type ApprovalStatus = 'pending' | 'approved' | 'rejected'

export type ProctoringLevel = 'standard' | 'strict'

export type ExamStatus = 'draft' | 'published' | 'active' | 'completed'

export type QuestionType = 'mcq' | 'coding' | 'short_answer'

export type NotificationType =
  | 'exam_scheduled'
  | 'streak_nudge'
  | 'announcement'
  | 'session_reminder'
  | 'session_marked'
  | 'graduation'
  | 'lineage_senior_active'
  | 'article_approved'

export type PostType = 'job' | 'project' | 'mentorship'

export type PostVisibility = 'lineage_only' | 'batch' | 'department'

export type ReadinessBand = 'strong' | 'building' | 'needs_attention' | 'at_risk'

// ──────────────────────────────────────────────────────────────
// Table row types
// ──────────────────────────────────────────────────────────────

export interface Batch {
  id: string
  batch_code: string
  start_date: string          // ISO date string
  end_date: string            // ISO date string
  status: BatchStatus
  created_at: string
}

export interface User {
  id: string
  email: string
  full_name: string
  roll_no: string | null
  batch_id: string | null
  role: UserRole
  app_role: AppRole
  team_id: string | null
  avatar_url: string | null
  linkedin_url: string | null
  current_company: string | null
  current_role_title: string | null
  mentorship_open: boolean
  onboarding_complete: boolean
  created_at: string
  updated_at: string
}

export interface Team {
  id: string
  batch_id: string
  team_name: string
  target_size: number
  created_at: string
}

export interface UserPermission {
  id: string
  user_id: string
  permission: string
  granted_by: string | null
  granted_at: string
}

export interface LineageMap {
  id: string
  junior_user_id: string
  senior_user_id: string
  roll_suffix: string
}

export interface PlacementSession {
  id: string
  batch_id: string
  scheduled_by: string
  session_date: string        // ISO date string
  session_time: string        // HH:MM:SS
  topic: string
  target_scope: SessionTargetScope
  created_at: string
}

export interface PlacementSessionTeam {
  session_id: string
  team_id: string
}

export interface PlacementAttendance {
  id: string
  session_id: string
  student_id: string
  status: AttendanceStatus
  marked_by: string
  note: string | null
  marked_at: string
}

export interface QuestionBank {
  id: string
  question_text: string
  option_a: string
  option_b: string
  option_c: string
  option_d: string
  correct_option: CorrectOption
  topic: QuestionTopic
  difficulty: QuestionDifficulty
  is_active: boolean
  created_by: string | null
  created_at: string
}

export interface DailyFiveStreak {
  user_id: string
  current_streak: number
  longest_streak: number
  freezes_remaining: number
  freezes_reset_month: number | null
  last_completed_date: string | null  // ISO date string
  total_days_completed: number
  running_accuracy_rate: number       // 0.00 to 100.00
  total_questions_answered: number
  total_questions_correct: number
  updated_at: string
}

export interface LeetcodeStats {
  user_id: string
  username: string | null
  total_solved: number
  easy_solved: number
  medium_solved: number
  hard_solved: number
  batch_easy_solved: number
  batch_medium_solved: number
  batch_hard_solved: number
  batch_weighted_score: number
  batch_percentile: number            // 0.00 to 100.00
  weekly_solved: number
  ranking: number | null
  synced_at: string
}

export interface DailyTask {
  id: string
  batch_id: string
  task_date: string                   // ISO date string
  task_type: 'leetcode' | 'core_subject'
  title: string
  description: string | null
  reference_url: string | null
  subject: string | null
  published_by: string
  created_at: string
}

export interface TaskCompletion {
  id: string
  task_id: string
  student_id: string
  completed: boolean
  completed_at: string | null
  verified_by: string | null
  verified_at: string | null
}

export interface Company {
  id: string
  batch_id: string
  company_name: string
  visit_date: string                  // ISO date string
  roles_offered: string[] | null
  package_band_min: number | null     // LPA
  package_band_max: number | null     // LPA
  eligibility_criteria: string | null
  rounds: string[] | null
  logged_by: string
  created_at: string
}

export interface PlacementLogEntry {
  id: string
  company_id: string
  student_id: string
  round_name: string
  experience_text: string
  is_anonymous: boolean
  approval_status: ApprovalStatus
  approved_by: string | null
  approved_at: string | null
  kb_article_id: string | null
  created_at: string
}

export interface ReadinessScore {
  user_id: string
  score: number                       // 0.00 to 100.00
  daily_five_score: number            // 0 to 30
  leetcode_score: number              // 0 to 25
  mock_exam_score: number             // 0 to 35
  session_score: number               // 0 to 10
  band: ReadinessBand                 // generated column
  computed_at: string
}

export interface ReadinessScoreHistory {
  id: string
  user_id: string
  score: number
  daily_five_score: number | null
  leetcode_score: number | null
  mock_exam_score: number | null
  session_score: number | null
  snapshot_date: string               // ISO date string
}

export interface KnowledgeBrainArticle {
  id: string
  title: string
  content: string
  summary: string | null
  author_id: string | null
  source: ArticleSource
  placement_log_entry_id: string | null
  tags: string[] | null
  company_name: string | null
  batch_year: string | null
  approval_status: ApprovalStatus
  approved_by: string | null
  approved_at: string | null
  view_count: number
  created_at: string
  updated_at: string
}

export interface KnowledgeEmbedding {
  id: string
  article_id: string
  chunk_index: number
  chunk_text: string
  embedding: number[] | null          // vector(1536)
  created_at: string
}

export interface MockExam {
  id: string
  title: string
  description: string | null
  target_batch_id: string | null
  created_by: string
  scheduled_at: string
  duration_minutes: number
  total_marks: number
  proctoring_level: ProctoringLevel
  status: ExamStatus
  created_at: string
}

export interface MockExamQuestion {
  id: string
  exam_id: string
  question_text: string
  question_type: QuestionType
  option_a: string | null
  option_b: string | null
  option_c: string | null
  option_d: string | null
  correct_option: string | null
  marks: number
  order_index: number
}

export interface MockExamResult {
  id: string
  exam_id: string
  student_id: string
  score: number                       // 0.00 to 100.00
  raw_marks: number
  submitted_at: string
  time_taken_seconds: number | null
  proctoring_flags: Json              // array of violation objects
}

export interface Announcement {
  id: string
  batch_id: string | null
  title: string
  body: string
  posted_by: string
  is_pinned: boolean
  created_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: NotificationType
  title: string
  body: string
  is_read: boolean
  reference_id: string | null
  reference_type: string | null
  created_at: string
}

export interface CollaborationPost {
  id: string
  posted_by: string
  post_type: PostType
  title: string
  description: string
  visibility: PostVisibility
  is_active: boolean
  created_at: string
}

export interface LineageMessage {
  id: string
  sender_id: string
  receiver_id: string
  message_text: string
  is_read: boolean
  sent_at: string
}

export interface AuditLog {
  id: string
  actor_id: string | null
  action: string
  target_table: string | null
  target_id: string | null
  metadata: Json | null
  created_at: string
}

// ──────────────────────────────────────────────────────────────
// Database type — used with createClient<Database>() in apps/web
// ──────────────────────────────────────────────────────────────

export interface Database {
  public: {
    Tables: {
      batches: {
        Row: Batch
        Insert: Omit<Batch, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<Batch, 'id'>>
      }
      users: {
        Row: User
        Insert: Omit<User, 'created_at' | 'updated_at'> & { created_at?: string; updated_at?: string }
        Update: Partial<Omit<User, 'id'>>
      }
      teams: {
        Row: Team
        Insert: Omit<Team, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<Team, 'id'>>
      }
      user_permissions: {
        Row: UserPermission
        Insert: Omit<UserPermission, 'id' | 'granted_at'> & { id?: string; granted_at?: string }
        Update: Partial<Omit<UserPermission, 'id'>>
      }
      lineage_map: {
        Row: LineageMap
        Insert: Omit<LineageMap, 'id'> & { id?: string }
        Update: Partial<Omit<LineageMap, 'id'>>
      }
      placement_sessions: {
        Row: PlacementSession
        Insert: Omit<PlacementSession, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<PlacementSession, 'id'>>
      }
      placement_session_teams: {
        Row: PlacementSessionTeam
        Insert: PlacementSessionTeam
        Update: Partial<PlacementSessionTeam>
      }
      placement_attendance: {
        Row: PlacementAttendance
        Insert: Omit<PlacementAttendance, 'id' | 'marked_at'> & { id?: string; marked_at?: string }
        Update: Partial<Omit<PlacementAttendance, 'id'>>
      }
      question_bank: {
        Row: QuestionBank
        Insert: Omit<QuestionBank, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<QuestionBank, 'id'>>
      }
      daily_five_streaks: {
        Row: DailyFiveStreak
        Insert: DailyFiveStreak
        Update: Partial<DailyFiveStreak>
      }
      leetcode_stats: {
        Row: LeetcodeStats
        Insert: LeetcodeStats
        Update: Partial<LeetcodeStats>
      }
      daily_tasks: {
        Row: DailyTask
        Insert: Omit<DailyTask, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<DailyTask, 'id'>>
      }
      task_completions: {
        Row: TaskCompletion
        Insert: Omit<TaskCompletion, 'id'> & { id?: string }
        Update: Partial<Omit<TaskCompletion, 'id'>>
      }
      companies: {
        Row: Company
        Insert: Omit<Company, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<Company, 'id'>>
      }
      placement_log_entries: {
        Row: PlacementLogEntry
        Insert: Omit<PlacementLogEntry, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<PlacementLogEntry, 'id'>>
      }
      readiness_scores: {
        Row: ReadinessScore
        Insert: Omit<ReadinessScore, 'band'> & { band?: ReadinessBand }
        Update: Partial<Omit<ReadinessScore, 'user_id' | 'band'>>
      }
      readiness_score_history: {
        Row: ReadinessScoreHistory
        Insert: Omit<ReadinessScoreHistory, 'id'> & { id?: string }
        Update: Partial<Omit<ReadinessScoreHistory, 'id'>>
      }
      knowledge_brain_articles: {
        Row: KnowledgeBrainArticle
        Insert: Omit<KnowledgeBrainArticle, 'id' | 'created_at' | 'updated_at'> & { id?: string; created_at?: string; updated_at?: string }
        Update: Partial<Omit<KnowledgeBrainArticle, 'id'>>
      }
      knowledge_embeddings: {
        Row: KnowledgeEmbedding
        Insert: Omit<KnowledgeEmbedding, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<KnowledgeEmbedding, 'id'>>
      }
      mock_exams: {
        Row: MockExam
        Insert: Omit<MockExam, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<MockExam, 'id'>>
      }
      mock_exam_questions: {
        Row: MockExamQuestion
        Insert: Omit<MockExamQuestion, 'id'> & { id?: string }
        Update: Partial<Omit<MockExamQuestion, 'id'>>
      }
      mock_exam_results: {
        Row: MockExamResult
        Insert: Omit<MockExamResult, 'id' | 'submitted_at'> & { id?: string; submitted_at?: string }
        Update: Partial<Omit<MockExamResult, 'id'>>
      }
      announcements: {
        Row: Announcement
        Insert: Omit<Announcement, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<Announcement, 'id'>>
      }
      notifications: {
        Row: Notification
        Insert: Omit<Notification, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<Notification, 'id'>>
      }
      collaboration_posts: {
        Row: CollaborationPost
        Insert: Omit<CollaborationPost, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: Partial<Omit<CollaborationPost, 'id'>>
      }
      lineage_messages: {
        Row: LineageMessage
        Insert: Omit<LineageMessage, 'id' | 'sent_at'> & { id?: string; sent_at?: string }
        Update: Partial<Omit<LineageMessage, 'id'>>
      }
      audit_logs: {
        Row: AuditLog
        Insert: Omit<AuditLog, 'id' | 'created_at'> & { id?: string; created_at?: string }
        Update: never  // audit logs are immutable
      }
    }
    Views: Record<string, never>
    Functions: {
      get_user_role: {
        Args: { uid: string }
        Returns: { role: UserRole; app_role: AppRole }[]
      }
      get_batch_for_user: {
        Args: { uid: string }
        Returns: string | null
      }
      get_team_for_user: {
        Args: { uid: string }
        Returns: string | null
      }
      is_student_in_my_team: {
        Args: { student_uid: string; team_leader_uid: string }
        Returns: boolean
      }
    }
    Enums: Record<string, never>
  }
}
