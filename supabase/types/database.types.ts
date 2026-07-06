// ============================================================
// PSGMX — supabase/types/database.types.ts (v2)
// Auto-generated types for the PSGMX Supabase schema.
// Re-generate with: supabase gen types typescript --local > supabase/types/database.types.ts
// ============================================================

export type UserRole   = 'student' | 'alumni' | 'faculty' | 'hod'
export type AppRole    = 'student' | 'team_leader' | 'coordinator' | 'placement_rep'
export type BatchStatus = 'active_junior' | 'active_senior' | 'graduated'
export type ApprovalStatus = 'pending' | 'approved' | 'rejected'
export type AttendanceStatus = 'present' | 'absent' | 'excused'
export type ExamStatus = 'draft' | 'published' | 'active' | 'completed'
export type ProctoringLevel = 'standard' | 'strict'
export type PostType = 'job' | 'project' | 'mentorship'
export type PostVisibility = 'lineage_only' | 'batch' | 'department'
export type ReadinessBand = 'strong' | 'building' | 'needs_attention' | 'at_risk'

export interface Database {
  public: {
    Tables: {
      batches: {
        Row: {
          id:          string
          batch_code:  string
          start_date:  string
          end_date:    string
          status:      BatchStatus
          created_at:  string
        }
        Insert: Omit<Database['public']['Tables']['batches']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['batches']['Insert']>
      }

      users: {
        Row: {
          id:                             string
          email:                          string
          full_name:                      string
          roll_no:                        string | null
          batch_id:                       string | null
          role:                           UserRole
          app_role:                       AppRole
          team_id:                        string | null
          avatar_url:                     string | null
          linkedin_url:                   string | null
          current_company:                string | null
          current_role_title:             string | null
          mentorship_open:                boolean
          onboarding_complete:            boolean
          gender:                         string | null
          dob:                            string | null
          role_label:                     string
          leetcode_username:              string | null
          ecampus_password:               string | null
          ecampus_password_set:           boolean
          birthday_notifications_enabled: boolean
          leetcode_notifications_enabled: boolean
          task_reminders_enabled:         boolean
          attendance_alerts_enabled:      boolean
          announcements_enabled:          boolean
          created_at:                     string
          updated_at:                     string
        }
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'created_at' | 'updated_at'> & {
          created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['users']['Insert']>
      }

      teams: {
        Row: {
          id:           string
          batch_id:     string
          team_name:    string
          target_size:  number
          created_at:   string
        }
        Insert: Omit<Database['public']['Tables']['teams']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['teams']['Insert']>
      }

      user_permissions: {
        Row: {
          id:          string
          user_id:     string
          permission:  string
          granted_by:  string | null
          granted_at:  string
        }
        Insert: Omit<Database['public']['Tables']['user_permissions']['Row'], 'id' | 'granted_at'> & {
          id?: string; granted_at?: string
        }
        Update: Partial<Database['public']['Tables']['user_permissions']['Insert']>
      }

      lineage_map: {
        Row: {
          id:              string
          junior_user_id:  string
          senior_user_id:  string
          roll_suffix:     string
        }
        Insert: Omit<Database['public']['Tables']['lineage_map']['Row'], 'id'> & { id?: string }
        Update: Partial<Database['public']['Tables']['lineage_map']['Insert']>
      }

      placement_sessions: {
        Row: {
          id:            string
          batch_id:      string
          scheduled_by:  string
          session_date:  string
          session_time:  string
          topic:         string
          target_scope:  'batch' | 'teams'
          created_at:    string
        }
        Insert: Omit<Database['public']['Tables']['placement_sessions']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['placement_sessions']['Insert']>
      }

      placement_attendance: {
        Row: {
          id:          string
          session_id:  string
          student_id:  string
          status:      AttendanceStatus
          marked_by:   string
          note:        string | null
          marked_at:   string
        }
        Insert: Omit<Database['public']['Tables']['placement_attendance']['Row'], 'id' | 'marked_at'> & {
          id?: string; marked_at?: string
        }
        Update: Partial<Database['public']['Tables']['placement_attendance']['Insert']>
      }

      question_bank: {
        Row: {
          id:             string
          question_text:  string
          option_a:       string
          option_b:       string
          option_c:       string
          option_d:       string
          correct_option: 'a' | 'b' | 'c' | 'd'
          topic:          string
          difficulty:     'easy' | 'medium' | 'hard'
          is_active:      boolean
          created_by:     string | null
          created_at:     string
        }
        Insert: Omit<Database['public']['Tables']['question_bank']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['question_bank']['Insert']>
      }

      daily_five_streaks: {
        Row: {
          user_id:                  string
          current_streak:           number
          longest_streak:           number
          freezes_remaining:        number
          freezes_reset_month:      number | null
          last_completed_date:      string | null
          total_days_completed:     number
          running_accuracy_rate:    number
          total_questions_answered: number
          total_questions_correct:  number
          updated_at:               string
        }
        Insert: Partial<Database['public']['Tables']['daily_five_streaks']['Row']> & { user_id: string }
        Update: Partial<Database['public']['Tables']['daily_five_streaks']['Row']>
      }

      leetcode_stats: {
        Row: {
          user_id:              string
          username:             string | null
          total_solved:         number
          easy_solved:          number
          medium_solved:        number
          hard_solved:          number
          batch_easy_solved:    number
          batch_medium_solved:  number
          batch_hard_solved:    number
          batch_weighted_score: number
          batch_percentile:     number
          weekly_solved:        number
          ranking:              number | null
          synced_at:            string
        }
        Insert: Partial<Database['public']['Tables']['leetcode_stats']['Row']> & { user_id: string }
        Update: Partial<Database['public']['Tables']['leetcode_stats']['Row']>
      }

      daily_tasks: {
        Row: {
          id:            string
          batch_id:      string
          task_date:     string
          task_type:     'leetcode' | 'core_subject'
          title:         string
          description:   string | null
          reference_url: string | null
          subject:       string | null
          published_by:  string
          created_at:    string
        }
        Insert: Omit<Database['public']['Tables']['daily_tasks']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['daily_tasks']['Insert']>
      }

      task_completions: {
        Row: {
          id:           string
          task_id:      string
          student_id:   string
          completed:    boolean
          completed_at: string | null
          verified_by:  string | null
          verified_at:  string | null
        }
        Insert: Omit<Database['public']['Tables']['task_completions']['Row'], 'id'> & { id?: string }
        Update: Partial<Database['public']['Tables']['task_completions']['Insert']>
      }

      companies: {
        Row: {
          id:                   string
          batch_id:             string
          company_name:         string
          visit_date:           string
          roles_offered:        string[] | null
          package_band_min:     number | null
          package_band_max:     number | null
          eligibility_criteria: string | null
          rounds:               string[] | null
          logged_by:            string
          created_at:           string
        }
        Insert: Omit<Database['public']['Tables']['companies']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['companies']['Insert']>
      }

      placement_log_entries: {
        Row: {
          id:               string
          company_id:       string
          student_id:       string
          round_name:       string
          experience_text:  string
          is_anonymous:     boolean
          approval_status:  ApprovalStatus
          approved_by:      string | null
          approved_at:      string | null
          kb_article_id:    string | null
          created_at:       string
        }
        Insert: Omit<Database['public']['Tables']['placement_log_entries']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['placement_log_entries']['Insert']>
      }

      readiness_scores: {
        Row: {
          user_id:          string
          score:            number
          daily_five_score: number
          leetcode_score:   number
          mock_exam_score:  number
          session_score:    number
          band:             ReadinessBand
          computed_at:      string
        }
        Insert: Omit<Database['public']['Tables']['readiness_scores']['Row'], 'band'> & { band?: ReadinessBand }
        Update: Partial<Database['public']['Tables']['readiness_scores']['Insert']>
      }

      readiness_score_history: {
        Row: {
          id:               string
          user_id:          string
          score:            number
          daily_five_score: number | null
          leetcode_score:   number | null
          mock_exam_score:  number | null
          session_score:    number | null
          snapshot_date:    string
        }
        Insert: Omit<Database['public']['Tables']['readiness_score_history']['Row'], 'id'> & { id?: string }
        Update: Partial<Database['public']['Tables']['readiness_score_history']['Insert']>
      }

      knowledge_brain_articles: {
        Row: {
          id:                      string
          title:                   string
          content:                 string
          summary:                 string | null
          author_id:               string | null
          source:                  'web' | 'flutter_placement_log'
          placement_log_entry_id:  string | null
          tags:                    string[] | null
          company_name:            string | null
          batch_year:              string | null
          approval_status:         ApprovalStatus
          approved_by:             string | null
          approved_at:             string | null
          view_count:              number
          search_vector:           string | null  // tsvector (treated as text in JS)
          created_at:              string
          updated_at:              string
        }
        Insert: Omit<Database['public']['Tables']['knowledge_brain_articles']['Row'], 'id' | 'created_at' | 'updated_at' | 'search_vector'> & {
          id?: string; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['knowledge_brain_articles']['Insert']>
      }

      knowledge_embeddings: {
        Row: {
          id:          string
          article_id:  string
          chunk_index: number
          chunk_text:  string
          embedding:   number[] | null  // vector(384) — gte-small
          created_at:  string
        }
        Insert: Omit<Database['public']['Tables']['knowledge_embeddings']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['knowledge_embeddings']['Insert']>
      }

      mock_exams: {
        Row: {
          id:                string
          title:             string
          description:       string | null
          target_batch_id:   string | null
          created_by:        string
          scheduled_at:      string
          duration_minutes:  number
          total_marks:       number
          proctoring_level:  ProctoringLevel
          status:            ExamStatus
          created_at:        string
        }
        Insert: Omit<Database['public']['Tables']['mock_exams']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['mock_exams']['Insert']>
      }

      mock_exam_questions: {
        Row: {
          id:             string
          exam_id:        string
          question_text:  string
          question_type:  'mcq' | 'coding' | 'short_answer'
          option_a:       string | null
          option_b:       string | null
          option_c:       string | null
          option_d:       string | null
          correct_option: string | null
          marks:          number
          order_index:    number
        }
        Insert: Omit<Database['public']['Tables']['mock_exam_questions']['Row'], 'id'> & { id?: string }
        Update: Partial<Database['public']['Tables']['mock_exam_questions']['Insert']>
      }

      mock_exam_results: {
        Row: {
          id:                  string
          exam_id:             string
          student_id:          string
          score:               number
          raw_marks:           number
          submitted_at:        string
          time_taken_seconds:  number | null
          proctoring_flags:    Array<{ type: string; timestamp: string }>
        }
        Insert: Omit<Database['public']['Tables']['mock_exam_results']['Row'], 'id' | 'submitted_at'> & {
          id?: string; submitted_at?: string
        }
        Update: Partial<Database['public']['Tables']['mock_exam_results']['Insert']>
      }

      announcements: {
        Row: {
          id:         string
          batch_id:   string | null
          title:      string
          body:       string
          posted_by:  string
          is_pinned:  boolean
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['announcements']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['announcements']['Insert']>
      }

      notifications: {
        Row: {
          id:             string
          user_id:        string
          type:           string
          title:          string
          body:           string
          is_read:        boolean
          reference_id:   string | null
          reference_type: string | null
          created_at:     string
        }
        Insert: Omit<Database['public']['Tables']['notifications']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['notifications']['Insert']>
      }

      collaboration_posts: {
        Row: {
          id:          string
          posted_by:   string
          post_type:   PostType
          title:       string
          description: string
          visibility:  PostVisibility
          is_active:   boolean
          created_at:  string
        }
        Insert: Omit<Database['public']['Tables']['collaboration_posts']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['collaboration_posts']['Insert']>
      }

      lineage_messages: {
        Row: {
          id:           string
          sender_id:    string
          receiver_id:  string
          message_text: string
          is_read:      boolean
          sent_at:      string
        }
        Insert: Omit<Database['public']['Tables']['lineage_messages']['Row'], 'id' | 'sent_at'> & {
          id?: string; sent_at?: string
        }
        Update: Partial<Database['public']['Tables']['lineage_messages']['Insert']>
      }

      audit_logs: {
        Row: {
          id:           string
          actor_id:     string | null
          action:       string
          target_table: string | null
          target_id:    string | null
          metadata:     Record<string, unknown> | null
          created_at:   string
        }
        Insert: Omit<Database['public']['Tables']['audit_logs']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['audit_logs']['Insert']>
      }
    }

    Functions: {
      get_user_role:                      { Args: { p_user_id: string }; Returns: { role: string; app_role: string }[] }
      get_batch_for_user:                 { Args: { p_user_id: string }; Returns: string }
      compute_readiness_score:            { Args: { p_user_id: string }; Returns: Record<string, unknown> }
      update_leetcode_username_unified:   { Args: { p_user_id: string; p_new_username: string }; Returns: Record<string, unknown> }
      recompute_batch_leetcode_percentiles: { Args: { p_batch_id: string }; Returns: number }
      submit_exam_server_side: {
        Args: {
          p_exam_id: string
          p_student_id: string
          p_answers: Record<string, string>
          p_time_taken_seconds: number
          p_proctoring_flags: Array<{ type: string; timestamp: string }>
        }
        Returns: Record<string, unknown>
      }
      graduate_batch: { Args: { p_batch_id: string }; Returns: Record<string, unknown> }
      knowledge_semantic_search: {
        Args: { query_embedding: number[]; match_threshold?: number; match_count?: number }
        Returns: Array<{ id: string; article_id: string; chunk_text: string; title: string; similarity: number }>
      }
    }
  }
}
