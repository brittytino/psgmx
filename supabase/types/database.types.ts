// ============================================================
// PSGMX — supabase/types/database.types.ts
// Regenerated from a live schema introspection (service_role probe against
// the actual Supabase project) plus the tables added in
// 08_security_fixes_sprint0.sql / 09_sprint1_schema_and_features.sql that
// do not exist yet until those migrations are run.
//
// The previous version of this file was hand-written against
// supabase/migrations/00_initial_schema.sql, which was NEVER applied to
// production — it used role/app_role/full_name/roll_no columns that do
// not exist live, causing 'never'-typed errors across the app.
//
// Re-generate properly after running the migrations:
//   supabase gen types typescript --project-id ucmskbgdpnolnyrmkotz --schema public > supabase/types/database.types.ts
// ============================================================

export interface Database {
  public: {
    Tables: {

      users: {
        Row: {
          id: string
          email: string
          personal_email: string | null
          college_email: string | null
          reg_no: string
          name: string
          team_id: string | null
          team_uuid: string | null
          batch: string
          gender: string | null
          roles: Record<string, unknown>
          leetcode_username: string | null
          dob: string | null
          birthday_notifications_enabled: boolean | null
          leetcode_notifications_enabled: boolean | null
          task_reminders_enabled: boolean | null
          attendance_alerts_enabled: boolean | null
          announcements_enabled: boolean | null
          created_at: string
          updated_at: string
          ecampus_password: string | null
          ecampus_password_set: boolean
          batch_id: string | null
          role_label: string
          onboarding_complete: boolean
          show_birthday_publicly: boolean
          mentorship_open: boolean
          avatar_url: string | null
          linkedin_url: string | null
          github_url: string | null
          current_company: string | null
          current_role_title: string | null
          skills: string[]
          interests: string[]
          career_goal: string | null
          arrears: Record<string, unknown>[]
        }
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'personal_email' | 'college_email' | 'team_id' | 'team_uuid' | 'gender' | 'leetcode_username' | 'dob' | 'birthday_notifications_enabled' | 'leetcode_notifications_enabled' | 'task_reminders_enabled' | 'attendance_alerts_enabled' | 'announcements_enabled' | 'created_at' | 'updated_at' | 'ecampus_password' | 'ecampus_password_set' | 'batch_id' | 'role_label' | 'onboarding_complete' | 'show_birthday_publicly' | 'mentorship_open' | 'avatar_url' | 'linkedin_url' | 'github_url' | 'current_company' | 'current_role_title' | 'skills' | 'interests' | 'career_goal' | 'arrears'> & {
          personal_email?: string | null
          college_email?: string | null
          team_id?: string | null
          team_uuid?: string | null
          gender?: string | null
          leetcode_username?: string | null
          dob?: string | null
          birthday_notifications_enabled?: boolean | null
          leetcode_notifications_enabled?: boolean | null
          task_reminders_enabled?: boolean | null
          attendance_alerts_enabled?: boolean | null
          announcements_enabled?: boolean | null
          created_at?: string
          updated_at?: string
          ecampus_password?: string | null
          ecampus_password_set?: boolean
          batch_id?: string | null
          role_label?: string
          onboarding_complete?: boolean
          show_birthday_publicly?: boolean
          mentorship_open?: boolean
          avatar_url?: string | null
          linkedin_url?: string | null
          github_url?: string | null
          current_company?: string | null
          current_role_title?: string | null
          skills?: string[]
          interests?: string[]
          career_goal?: string | null
          arrears?: Record<string, unknown>[]
        }
        Update: Partial<Database['public']['Tables']['users']['Insert']>
        Relationships: []
      }

      batches: {
        Row: {
          id: string
          batch_code: string
          start_year: number
          end_year: number
          status: string
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['batches']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['batches']['Insert']>
        Relationships: []
      }

      teams: {
        Row: {
          id: string
          batch_id: string
          team_name: string
          team_code: string
          team_leader_id: string | null
          target_size: number
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['teams']['Row'], 'id' | 'team_leader_id' | 'target_size' | 'created_at' | 'updated_at'> & {
          id?: string
          team_leader_id?: string | null
          target_size?: number
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['teams']['Insert']>
        Relationships: []
      }

      user_permissions: {
        Row: {
          user_id: string
          permission_key: string
          granted_by: string | null
          granted_at: string
        }
        Insert: Omit<Database['public']['Tables']['user_permissions']['Row'], 'granted_by' | 'granted_at'> & {
          granted_by?: string | null
          granted_at?: string
        }
        Update: Partial<Database['public']['Tables']['user_permissions']['Insert']>
        Relationships: []
      }

      whitelist: {
        Row: {
          email: string
          personal_email: string | null
          college_email: string | null
          name: string | null
          reg_no: string | null
          batch: string | null
          batch_id: string | null
          team_id: string | null
          team_uuid: string | null
          gender: string | null
          dob: string | null
          leetcode_username: string | null
          roles: Record<string, unknown> | null
          role_label: string
          created_at: string | null
        }
        Insert: Omit<Database['public']['Tables']['whitelist']['Row'], 'name' | 'reg_no' | 'personal_email' | 'college_email' | 'batch' | 'batch_id' | 'team_id' | 'team_uuid' | 'gender' | 'dob' | 'leetcode_username' | 'roles' | 'role_label' | 'created_at'> & {
          name?: string | null
          reg_no?: string | null
          personal_email?: string | null
          college_email?: string | null
          batch?: string | null
          batch_id?: string | null
          team_id?: string | null
          team_uuid?: string | null
          gender?: string | null
          dob?: string | null
          leetcode_username?: string | null
          roles?: Record<string, unknown> | null
          role_label?: string
          created_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['whitelist']['Insert']>
        Relationships: []
      }

      whitelist_email_aliases: {
        Row: {
          email: string
          whitelist_email: string
          email_type: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['whitelist_email_aliases']['Row'], 'created_at'> & {
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['whitelist_email_aliases']['Insert']>
        Relationships: []
      }

      user_auth_identities: {
        Row: {
          auth_user_id: string
          user_id: string
          email: string
          email_type: string
          verified_at: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['user_auth_identities']['Row'], 'verified_at' | 'created_at'> & {
          verified_at?: string | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['user_auth_identities']['Insert']>
        Relationships: []
      }

      app_config: {
        Row: {
          id: string
          min_required_version: string
          latest_version: string
          force_update: boolean
          update_message: string | null
          github_release_url: string | null
          android_download_url: string | null
          ios_download_url: string | null
          emergency_block: boolean
          emergency_message: string | null
          created_at: string
          updated_at: string
          updated_by: string | null
          rollout_stage: string
          enabled_batch_ids: string[]
          pilot_user_ids: string[]
        }
        Insert: Omit<Database['public']['Tables']['app_config']['Row'], 'id' | 'min_required_version' | 'latest_version' | 'force_update' | 'update_message' | 'github_release_url' | 'android_download_url' | 'ios_download_url' | 'emergency_block' | 'emergency_message' | 'created_at' | 'updated_at' | 'updated_by' | 'rollout_stage' | 'enabled_batch_ids' | 'pilot_user_ids'> & {
          id?: string
          min_required_version?: string
          latest_version?: string
          force_update?: boolean
          update_message?: string | null
          github_release_url?: string | null
          android_download_url?: string | null
          ios_download_url?: string | null
          emergency_block?: boolean
          emergency_message?: string | null
          created_at?: string
          updated_at?: string
          updated_by?: string | null
          rollout_stage?: string
          enabled_batch_ids?: string[]
          pilot_user_ids?: string[]
        }
        Update: Partial<Database['public']['Tables']['app_config']['Insert']>
        Relationships: []
      }

      announcements: {
        Row: {
          id: string
          batch_id: string | null
          title: string
          message: string
          is_priority: boolean
          expiry_date: string | null
          created_by: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['announcements']['Row'], 'id' | 'batch_id' | 'is_priority' | 'expiry_date' | 'created_by' | 'created_at'> & {
          id?: string
          batch_id?: string | null
          is_priority?: boolean
          expiry_date?: string | null
          created_by?: string | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['announcements']['Insert']>
        Relationships: []
      }

      audit_logs: {
        Row: {
          id: string
          batch_id: string | null
          actor_id: string
          action: string
          entity_type: string
          entity_id: string | null
          metadata: Record<string, unknown> | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['audit_logs']['Row'], 'id' | 'batch_id' | 'entity_id' | 'metadata' | 'created_at'> & {
          id?: string
          batch_id?: string | null
          entity_id?: string | null
          metadata?: Record<string, unknown> | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['audit_logs']['Insert']>
        Relationships: []
      }

      notifications: {
        Row: {
          id: string
          batch_id: string | null
          title: string
          message: string
          notification_type: string
          tone: string | null
          target_audience: string
          generated_at: string
          valid_until: string | null
          created_by: string | null
          is_active: boolean
          target_user_id: string | null
          action_path: string | null
          category: 'action_required' | 'scheduled_reminder' | 'progress' | 'community' | 'announcement' | 'system'
        }
        Insert: Omit<Database['public']['Tables']['notifications']['Row'], 'id' | 'batch_id' | 'tone' | 'generated_at' | 'valid_until' | 'created_by' | 'is_active' | 'target_user_id' | 'action_path' | 'category'> & {
          id?: string
          batch_id?: string | null
          tone?: string | null
          generated_at?: string
          valid_until?: string | null
          created_by?: string | null
          is_active?: boolean
          target_user_id?: string | null
          action_path?: string | null
          category?: 'action_required' | 'scheduled_reminder' | 'progress' | 'community' | 'announcement' | 'system'
        }
        Update: Partial<Database['public']['Tables']['notifications']['Insert']>
        Relationships: []
      }

      notification_reads: {
        Row: {
          id: string
          notification_id: string
          user_id: string
          read_at: string
          dismissed_at: string | null
        }
        Insert: Omit<Database['public']['Tables']['notification_reads']['Row'], 'id' | 'read_at' | 'dismissed_at'> & {
          id?: string
          read_at?: string
          dismissed_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['notification_reads']['Insert']>
        Relationships: []
      }

      companies: {
        Row: {
          id: string
          batch_id: string
          name: string
          visit_date: string
          roles_offered: string[]
          package_band: string | null
          eligibility: string | null
          rounds: unknown[]
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['companies']['Row'], 'id' | 'package_band' | 'eligibility' | 'created_at' | 'updated_at'> & {
          id?: string
          package_band?: string | null
          eligibility?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['companies']['Insert']>
        Relationships: []
      }

      placement_log_entries: {
        Row: {
          id: string
          company_id: string
          user_id: string
          round_name: string
          experience_text: string
          is_moderated: boolean
          moderated_by: string | null
          approval_status: 'pending' | 'approved' | 'rejected'
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['placement_log_entries']['Row'], 'id' | 'is_moderated' | 'moderated_by' | 'approval_status' | 'created_at' | 'updated_at'> & {
          id?: string
          is_moderated?: boolean
          moderated_by?: string | null
          approval_status?: 'pending' | 'approved' | 'rejected'
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['placement_log_entries']['Insert']>
        Relationships: []
      }

      placement_sessions: {
        Row: {
          id: string
          batch_id: string
          scheduled_by: string
          session_datetime: string
          topic: string
          description: string | null
          target_team_ids: string[] | null
          created_at: string
          updated_at: string
          session_type: string | null
          session_mode: string | null
          duration_minutes: number | null
          location: string | null
          is_locked: boolean | null
        }
        Insert: Omit<Database['public']['Tables']['placement_sessions']['Row'], 'id' | 'description' | 'target_team_ids' | 'created_at' | 'updated_at' | 'session_type' | 'session_mode' | 'duration_minutes' | 'location' | 'is_locked'> & {
          id?: string
          description?: string | null
          target_team_ids?: string[] | null
          created_at?: string
          updated_at?: string
          session_type?: string | null
          session_mode?: string | null
          duration_minutes?: number | null
          location?: string | null
          is_locked?: boolean | null
        }
        Update: Partial<Database['public']['Tables']['placement_sessions']['Insert']>
        Relationships: []
      }

      placement_attendance: {
        Row: {
          session_id: string
          user_id: string
          status: string
          marked_by: string
          marked_at: string
          notes: string | null
        }
        Insert: Omit<Database['public']['Tables']['placement_attendance']['Row'], 'marked_at' | 'notes'> & {
          marked_at?: string
          notes?: string | null
        }
        Update: Partial<Database['public']['Tables']['placement_attendance']['Insert']>
        Relationships: []
      }

      placement_attendance_summary: {
        Row: {
          user_id: string | null
          batch_id: string | null
          eligible_sessions: number | null
          attended_sessions: number | null
          attendance_pct: number | null
        }
        Insert: Omit<Database['public']['Tables']['placement_attendance_summary']['Row'], 'user_id' | 'batch_id' | 'eligible_sessions' | 'attended_sessions' | 'attendance_pct'> & {
          user_id?: string | null
          batch_id?: string | null
          eligible_sessions?: number | null
          attended_sessions?: number | null
          attendance_pct?: number | null
        }
        Update: Partial<Database['public']['Tables']['placement_attendance_summary']['Insert']>
        Relationships: []
      }

      attendance_records: {
        Row: {
          id: string
          user_id: string
          date: string
          team_id: string
          status: string
          marked_by: string | null
          notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['attendance_records']['Row'], 'id' | 'marked_by' | 'notes' | 'created_at' | 'updated_at'> & {
          id?: string
          marked_by?: string | null
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['attendance_records']['Insert']>
        Relationships: []
      }

      scheduled_attendance_dates: {
        Row: {
          id: string
          batch_id: string | null
          date: string
          is_working_day: boolean
          scheduled_by: string | null
          notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['scheduled_attendance_dates']['Row'], 'id' | 'batch_id' | 'is_working_day' | 'scheduled_by' | 'notes' | 'created_at' | 'updated_at'> & {
          id?: string
          batch_id?: string | null
          is_working_day?: boolean
          scheduled_by?: string | null
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['scheduled_attendance_dates']['Insert']>
        Relationships: []
      }

      student_attendance_summary: {
        Row: {
          student_id: string | null
          user_id: string | null
          email: string | null
          reg_no: string | null
          name: string | null
          team_id: string | null
          batch: string | null
          present_count: number | null
          absent_count: number | null
          total_working_days: number | null
          attendance_percentage: number | null
        }
        Insert: Omit<Database['public']['Tables']['student_attendance_summary']['Row'], 'student_id' | 'user_id' | 'email' | 'reg_no' | 'name' | 'team_id' | 'batch' | 'present_count' | 'absent_count' | 'total_working_days' | 'attendance_percentage'> & {
          student_id?: string | null
          user_id?: string | null
          email?: string | null
          reg_no?: string | null
          name?: string | null
          team_id?: string | null
          batch?: string | null
          present_count?: number | null
          absent_count?: number | null
          total_working_days?: number | null
          attendance_percentage?: number | null
        }
        Update: Partial<Database['public']['Tables']['student_attendance_summary']['Insert']>
        Relationships: []
      }

      defaulter_flags: {
        Row: {
          id: string
          user_id: string
          defaulter_status: boolean
          defaulter_reason: string
          consecutive_absences: number
          attendance_percentage: number | null
          detected_at: string
          resolved_at: string | null
          resolved_by: string | null
          notes: string | null
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['defaulter_flags']['Row'], 'id' | 'defaulter_status' | 'defaulter_reason' | 'consecutive_absences' | 'attendance_percentage' | 'detected_at' | 'resolved_at' | 'resolved_by' | 'notes' | 'updated_at'> & {
          id?: string
          defaulter_status?: boolean
          defaulter_reason?: string
          consecutive_absences?: number
          attendance_percentage?: number | null
          detected_at?: string
          resolved_at?: string | null
          resolved_by?: string | null
          notes?: string | null
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['defaulter_flags']['Insert']>
        Relationships: []
      }

      daily_tasks: {
        Row: {
          id: string
          batch_id: string | null
          date: string
          topic_type: string
          title: string
          reference_link: string | null
          subject: string | null
          uploaded_by: string
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['daily_tasks']['Row'], 'id' | 'batch_id' | 'reference_link' | 'subject' | 'created_at' | 'updated_at'> & {
          id?: string
          batch_id?: string | null
          reference_link?: string | null
          subject?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['daily_tasks']['Insert']>
        Relationships: []
      }

      task_completions: {
        Row: {
          id: string
          user_id: string
          task_date: string
          completed: boolean
          completed_at: string | null
          verified_by: string | null
          verified_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['task_completions']['Row'], 'id' | 'completed' | 'completed_at' | 'verified_by' | 'verified_at' | 'created_at' | 'updated_at'> & {
          id?: string
          completed?: boolean
          completed_at?: string | null
          verified_by?: string | null
          verified_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['task_completions']['Insert']>
        Relationships: []
      }

      daily_five_streaks: {
        Row: {
          user_id: string
          current_streak: number
          longest_streak: number
          freezes_remaining: number
          freezes_reset_month: string
          last_completed_date: string | null
          last_accuracy_rate: number | null
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['daily_five_streaks']['Row'], 'current_streak' | 'longest_streak' | 'freezes_remaining' | 'freezes_reset_month' | 'last_completed_date' | 'last_accuracy_rate' | 'updated_at'> & {
          current_streak?: number
          longest_streak?: number
          freezes_remaining?: number
          freezes_reset_month?: string
          last_completed_date?: string | null
          last_accuracy_rate?: number | null
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['daily_five_streaks']['Insert']>
        Relationships: []
      }

      leetcode_stats: {
        Row: {
          username: string
          total_solved: number | null
          easy_solved: number | null
          medium_solved: number | null
          hard_solved: number | null
          ranking: number | null
          weekly_score: number | null
          profile_picture: string | null
          last_updated: string | null
          created_at: string | null
        }
        Insert: Omit<Database['public']['Tables']['leetcode_stats']['Row'], 'total_solved' | 'easy_solved' | 'medium_solved' | 'hard_solved' | 'ranking' | 'weekly_score' | 'profile_picture' | 'last_updated' | 'created_at'> & {
          total_solved?: number | null
          easy_solved?: number | null
          medium_solved?: number | null
          hard_solved?: number | null
          ranking?: number | null
          weekly_score?: number | null
          profile_picture?: string | null
          last_updated?: string | null
          created_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['leetcode_stats']['Insert']>
        Relationships: []
      }

      question_bank: {
        Row: {
          id: string
          question_text: string
          options: unknown[]
          correct_option: number
          topic: string
          difficulty: string
          created_by: string | null
          created_at: string
          updated_at: string
          is_active: boolean
        }
        Insert: Omit<Database['public']['Tables']['question_bank']['Row'], 'id' | 'created_by' | 'created_at' | 'updated_at' | 'is_active'> & {
          id?: string
          created_by?: string | null
          created_at?: string
          updated_at?: string
          is_active?: boolean
        }
        Update: Partial<Database['public']['Tables']['question_bank']['Insert']>
        Relationships: []
      }

      daily_five_attempts: {
        Row: {
          id: string
          user_id: string
          attempt_date: string
          question_ids: string[]
          started_at: string
          submitted_at: string | null
          correct_count: number | null
          accuracy_rate: number | null
          flagged: boolean
          flag_reason: string | null
        }
        Insert: Omit<Database['public']['Tables']['daily_five_attempts']['Row'], 'id' | 'attempt_date' | 'started_at' | 'submitted_at' | 'correct_count' | 'accuracy_rate' | 'flagged' | 'flag_reason'> & {
          id?: string
          attempt_date?: string
          started_at?: string
          submitted_at?: string | null
          correct_count?: number | null
          accuracy_rate?: number | null
          flagged?: boolean
          flag_reason?: string | null
        }
        Update: Partial<Database['public']['Tables']['daily_five_attempts']['Insert']>
        Relationships: []
      }

      ecampus_attendance: {
        Row: {
          id: string
          reg_no: string
          data: Record<string, unknown>
          synced_at: string
        }
        Insert: Omit<Database['public']['Tables']['ecampus_attendance']['Row'], 'id' | 'synced_at'> & {
          id?: string
          synced_at?: string
        }
        Update: Partial<Database['public']['Tables']['ecampus_attendance']['Insert']>
        Relationships: []
      }

      ecampus_cgpa: {
        Row: {
          id: string
          reg_no: string
          data: Record<string, unknown>
          synced_at: string
        }
        Insert: Omit<Database['public']['Tables']['ecampus_cgpa']['Row'], 'id' | 'synced_at'> & {
          id?: string
          synced_at?: string
        }
        Update: Partial<Database['public']['Tables']['ecampus_cgpa']['Insert']>
        Relationships: []
      }

      ecampus_ca_marks: {
        Row: {
          id: string
          reg_no: string
          data: Record<string, unknown>
          synced_at: string
        }
        Insert: Omit<Database['public']['Tables']['ecampus_ca_marks']['Row'], 'id' | 'synced_at'> & {
          id?: string
          synced_at?: string
        }
        Update: Partial<Database['public']['Tables']['ecampus_ca_marks']['Insert']>
        Relationships: []
      }

      ecampus_ca_timetable: {
        Row: {
          id: string
          reg_no: string
          data: Record<string, unknown>
          synced_at: string
        }
        Insert: Omit<Database['public']['Tables']['ecampus_ca_timetable']['Row'], 'id' | 'synced_at'> & {
          id?: string
          synced_at?: string
        }
        Update: Partial<Database['public']['Tables']['ecampus_ca_timetable']['Insert']>
        Relationships: []
      }

      ca_timetable_global: {
        Row: {
          id: number
          data: Record<string, unknown>
          synced_at: string
          synced_by: string | null
        }
        Insert: Omit<Database['public']['Tables']['ca_timetable_global']['Row'], 'id' | 'synced_at' | 'synced_by'> & {
          id?: number
          synced_at?: string
          synced_by?: string | null
        }
        Update: Partial<Database['public']['Tables']['ca_timetable_global']['Insert']>
        Relationships: []
      }

      attendance_days: {
        Row: {
          date: string
          is_working_day: boolean
          decided_by: string | null
          reason: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['attendance_days']['Row'], 'is_working_day' | 'decided_by' | 'reason' | 'created_at' | 'updated_at'> & {
          is_working_day?: boolean
          decided_by?: string | null
          reason?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['attendance_days']['Insert']>
        Relationships: []
      }

      ecampus_bunked_subjects: {
        Row: {
          id: string
          reg_no: string
          course_code: string
          course_title: string | null
          total_hours: number
          total_present: number
          percentage: number | null
          can_bunk: number
          need_attend: number
          synced_at: string
        }
        Insert: Omit<Database['public']['Tables']['ecampus_bunked_subjects']['Row'], 'id' | 'course_title' | 'total_hours' | 'total_present' | 'percentage' | 'can_bunk' | 'need_attend' | 'synced_at'> & {
          id?: string
          course_title?: string | null
          total_hours?: number
          total_present?: number
          percentage?: number | null
          can_bunk?: number
          need_attend?: number
          synced_at?: string
        }
        Update: Partial<Database['public']['Tables']['ecampus_bunked_subjects']['Insert']>
        Relationships: []
      }

      otp_rate_log: {
        Row: {
          id: string
          email: string
          sent_at: string
        }
        Insert: Omit<Database['public']['Tables']['otp_rate_log']['Row'], 'id' | 'sent_at'> & {
          id?: string
          sent_at?: string
        }
        Update: Partial<Database['public']['Tables']['otp_rate_log']['Insert']>
        Relationships: []
      }

      readiness_scores: {
        Row: {
          id: string
          user_id: string
          score: number
          computed_at: string
          components_json: Record<string, unknown>
        }
        Insert: Omit<Database['public']['Tables']['readiness_scores']['Row'], 'id' | 'computed_at'> & {
          id?: string
          computed_at?: string
        }
        Update: Partial<Database['public']['Tables']['readiness_scores']['Insert']>
        Relationships: []
      }

      v_ecampus_attendance_summary: {
        Row: {
          reg_no: string | null
          name: string | null
          total_hours: number | null
          total_present: number | null
          overall_pct: number | null
          can_bunk: number | null
          need_attend: number | null
          synced_at: string | null
        }
        Insert: Omit<Database['public']['Tables']['v_ecampus_attendance_summary']['Row'], 'reg_no' | 'name' | 'total_hours' | 'total_present' | 'overall_pct' | 'can_bunk' | 'need_attend' | 'synced_at'> & {
          reg_no?: string | null
          name?: string | null
          total_hours?: number | null
          total_present?: number | null
          overall_pct?: number | null
          can_bunk?: number | null
          need_attend?: number | null
          synced_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['v_ecampus_attendance_summary']['Insert']>
        Relationships: []
      }

      v_ecampus_cgpa_summary: {
        Row: {
          reg_no: string | null
          name: string | null
          cgpa: number | null
          total_credits: number | null
          latest_semester: string | null
          total_semesters: number | null
          synced_at: string | null
        }
        Insert: Omit<Database['public']['Tables']['v_ecampus_cgpa_summary']['Row'], 'reg_no' | 'name' | 'cgpa' | 'total_credits' | 'latest_semester' | 'total_semesters' | 'synced_at'> & {
          reg_no?: string | null
          name?: string | null
          cgpa?: number | null
          total_credits?: number | null
          latest_semester?: string | null
          total_semesters?: number | null
          synced_at?: string | null
        }
        Update: Partial<Database['public']['Tables']['v_ecampus_cgpa_summary']['Insert']>
        Relationships: []
      }


      user_ecampus_credentials: {
        Row: {
          user_id:            string
          encrypted_password: string
          updated_at:         string
        }
        Insert: Database['public']['Tables']['user_ecampus_credentials']['Row']
        Update: Partial<Database['public']['Tables']['user_ecampus_credentials']['Insert']>
        Relationships: []
      }

      knowledge_brain_articles: {
        Row: {
          id:              string
          author_id:       string
          title:           string
          summary:         string | null
          content:         string
          tags:            string[]
          company_name:    string | null
          source:          string | null
          batch_year:      string | null
          view_count:      number
          approval_status: 'pending' | 'approved' | 'rejected'
          search_vector:   unknown | null
          reviewed_by:     string | null
          reviewed_at:     string | null
          created_at:      string
          updated_at:      string
        }
        Insert: Omit<Database['public']['Tables']['knowledge_brain_articles']['Row'], 'id' | 'summary' | 'tags' | 'company_name' | 'source' | 'batch_year' | 'view_count' | 'approval_status' | 'search_vector' | 'reviewed_by' | 'reviewed_at' | 'created_at' | 'updated_at'> & {
          id?: string; summary?: string | null; tags?: string[]; company_name?: string | null
          source?: string | null; batch_year?: string | null; view_count?: number
          approval_status?: 'pending' | 'approved' | 'rejected'
          search_vector?: unknown | null; reviewed_by?: string | null; reviewed_at?: string | null
          created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['knowledge_brain_articles']['Insert']>
        Relationships: []
      }

      knowledge_embeddings: {
        Row: {
          id:          string
          article_id:  string
          chunk_text:  string
          chunk_index: number
          embedding:   number[] | null
          created_at:  string
        }
        Insert: Omit<Database['public']['Tables']['knowledge_embeddings']['Row'], 'id' | 'chunk_index' | 'embedding' | 'created_at'> & {
          id?: string; chunk_index?: number; embedding?: number[] | null; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['knowledge_embeddings']['Insert']>
        Relationships: []
      }

      ai_query_logs: {
        Row: {
          id:         string
          user_id:    string | null
          query_text: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['ai_query_logs']['Row'], 'id' | 'user_id' | 'created_at'> & {
          id?: string; user_id?: string | null; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['ai_query_logs']['Insert']>
        Relationships: []
      }

      lineage_map: {
        Row: {
          id:             string
          student_id:     string
          senior_user_id: string | null
          senior_quote:   string | null
          assigned_at:    string
          assigned_by:    string | null
        }
        Insert: Omit<Database['public']['Tables']['lineage_map']['Row'], 'id' | 'senior_user_id' | 'senior_quote' | 'assigned_at' | 'assigned_by'> & {
          id?: string; senior_user_id?: string | null; senior_quote?: string | null
          assigned_at?: string; assigned_by?: string | null
        }
        Update: Partial<Database['public']['Tables']['lineage_map']['Insert']>
        Relationships: []
      }

      fyp_projects: {
        Row: {
          id:                 string
          batch_id:           string | null
          student_id:         string
          title:              string
          description:        string | null
          guide_name:         string | null
          team_members_count: number
          status:             'proposal' | 'in_progress' | 'completed' | 'archived'
          repository_url:     string | null
          domain:             string | null
          problem_statement:  string | null
          architecture_summary: string | null
          demonstration_url:  string | null
          evidence_confidence: 'low' | 'medium' | 'high'
          created_at:         string
          updated_at:         string
        }
        Insert: Omit<Database['public']['Tables']['fyp_projects']['Row'], 'id' | 'batch_id' | 'description' | 'guide_name' | 'team_members_count' | 'status' | 'repository_url' | 'domain' | 'problem_statement' | 'architecture_summary' | 'demonstration_url' | 'evidence_confidence' | 'created_at' | 'updated_at'> & {
          id?: string; batch_id?: string | null; description?: string | null; guide_name?: string | null
          team_members_count?: number; status?: 'proposal' | 'in_progress' | 'completed' | 'archived'
          repository_url?: string | null; domain?: string | null; problem_statement?: string | null
          architecture_summary?: string | null; demonstration_url?: string | null
          evidence_confidence?: 'low' | 'medium' | 'high'; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['fyp_projects']['Insert']>
        Relationships: []
      }

      fyp_progress_logs: {
        Row: {
          id:         string
          project_id: string
          student_id: string
          note:       string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['fyp_progress_logs']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['fyp_progress_logs']['Insert']>
        Relationships: []
      }

      fyp_feedback: {
        Row: {
          id:         string
          project_id: string
          faculty_id: string
          comment:    string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['fyp_feedback']['Row'], 'id' | 'created_at'> & {
          id?: string; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['fyp_feedback']['Insert']>
        Relationships: []
      }

      mock_exams: {
        Row: {
          id:               string
          title:            string
          description:      string | null
          duration_minutes: number
          total_marks:      number
          exam_date:        string | null
          batch_id:         string | null
          created_by:       string | null
          created_at:       string
        }
        Insert: Omit<Database['public']['Tables']['mock_exams']['Row'], 'id' | 'description' | 'duration_minutes' | 'total_marks' | 'exam_date' | 'batch_id' | 'created_by' | 'created_at'> & {
          id?: string; description?: string | null; duration_minutes?: number; total_marks?: number; exam_date?: string | null
          batch_id?: string | null; created_by?: string | null; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['mock_exams']['Insert']>
        Relationships: []
      }

      mock_exam_questions: {
        Row: {
          id:             string
          exam_id:        string
          question_text:  string
          option_a:       string | null
          option_b:       string | null
          option_c:       string | null
          option_d:       string | null
          correct_option: 'A' | 'B' | 'C' | 'D'
          marks:          number
          order_index:    number
          created_at:     string
        }
        Insert: Omit<Database['public']['Tables']['mock_exam_questions']['Row'], 'id' | 'option_a' | 'option_b' | 'option_c' | 'option_d' | 'marks' | 'order_index' | 'created_at'> & {
          id?: string; option_a?: string | null; option_b?: string | null; option_c?: string | null; option_d?: string | null
          marks?: number; order_index?: number; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['mock_exam_questions']['Insert']>
        Relationships: []
      }

      mock_exam_results: {
        Row: {
          id:               string
          exam_id:          string
          student_id:       string
          session_token:    string
          started_at:       string | null
          submitted_at:     string | null
          score:            number | null
          raw_marks:        number | null
          out_of:           number | null
          total_questions:  number | null
          proctoring_flags: unknown
          status:           'in_progress' | 'submitted' | 'auto_submitted' | 'voided'
          voided_by:        string | null
          reflection:       string | null
          reflected_at:     string | null
          created_at:       string
        }
        Insert: Omit<Database['public']['Tables']['mock_exam_results']['Row'], 'id' | 'session_token' | 'started_at' | 'submitted_at' | 'score' | 'raw_marks' | 'out_of' | 'total_questions' | 'proctoring_flags' | 'status' | 'voided_by' | 'reflection' | 'reflected_at' | 'created_at'> & {
          id?: string; session_token?: string; started_at?: string | null; submitted_at?: string | null
          score?: number | null; raw_marks?: number | null; out_of?: number | null; total_questions?: number | null; proctoring_flags?: unknown
          status?: 'in_progress' | 'submitted' | 'auto_submitted' | 'voided'; voided_by?: string | null
          reflection?: string | null; reflected_at?: string | null; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['mock_exam_results']['Insert']>
        Relationships: []
      }

      user_feedback: {
        Row: {
          id:            string
          user_id:       string
          category:      string
          feedback_text: string
          rating:        number | null
          created_at:    string
        }
        Insert: Omit<Database['public']['Tables']['user_feedback']['Row'], 'id' | 'category' | 'rating' | 'created_at'> & {
          id?: string; category?: string; rating?: number | null; created_at?: string
        }
        Update: Partial<Database['public']['Tables']['user_feedback']['Insert']>
        Relationships: []
      }

      collaboration_posts: {
        Row: {
          id:          string
          post_type:   'job' | 'project' | 'mentorship' | 'learning_event' | 'career_information' | 'unofficial_opportunity'
          title:       string
          description: string
          visibility:  'lineage_only' | 'batch' | 'department'
          is_active:   boolean
          posted_by:   string
          created_at:  string
          disclaimer:  string
        }
        Insert: Omit<Database['public']['Tables']['collaboration_posts']['Row'], 'id' | 'visibility' | 'is_active' | 'created_at' | 'disclaimer'> & {
          id?: string; visibility?: 'lineage_only' | 'batch' | 'department'; is_active?: boolean; created_at?: string
          disclaimer?: string
        }
        Update: Partial<Database['public']['Tables']['collaboration_posts']['Insert']>
        Relationships: []
      }

      preparation_tracks: {
        Row: {
          id: string
          batch_id: string | null
          title: string
          summary: string
          stage: 'foundation' | 'proof' | 'all'
          skill_domains: string[]
          difficulty: 'foundation' | 'intermediate' | 'advanced' | 'adaptive'
          estimated_weeks: number
          is_active: boolean
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['preparation_tracks']['Row'], 'id' | 'batch_id' | 'stage' | 'skill_domains' | 'difficulty' | 'estimated_weeks' | 'is_active' | 'created_at' | 'updated_at'> & {
          id?: string; batch_id?: string | null; stage?: 'foundation' | 'proof' | 'all'; skill_domains?: string[]
          difficulty?: 'foundation' | 'intermediate' | 'advanced' | 'adaptive'; estimated_weeks?: number
          is_active?: boolean; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['preparation_tracks']['Insert']>
        Relationships: []
      }

      interview_patterns: {
        Row: {
          id: string
          author_id: string
          title: string
          pattern_type: 'aptitude_screening' | 'coding_round' | 'technical_deep_dive' | 'fyp_discussion' | 'behavioural' | 'group_discussion' | 'general'
          historical_context: string | null
          preparation_helped: string
          mistakes: string | null
          example_themes: string[]
          advice: string
          company_name: string | null
          batch_year: string | null
          approval_status: 'draft' | 'pending' | 'changes_requested' | 'approved' | 'rejected' | 'retired'
          reviewed_by: string | null
          reviewed_at: string | null
          review_notes: string | null
          review_due_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['interview_patterns']['Row'], 'id' | 'historical_context' | 'mistakes' | 'example_themes' | 'company_name' | 'batch_year' | 'approval_status' | 'reviewed_by' | 'reviewed_at' | 'review_notes' | 'review_due_at' | 'created_at' | 'updated_at'> & {
          id?: string; historical_context?: string | null; mistakes?: string | null; example_themes?: string[]
          company_name?: string | null; batch_year?: string | null
          approval_status?: 'draft' | 'pending' | 'changes_requested' | 'approved' | 'rejected' | 'retired'
          reviewed_by?: string | null; reviewed_at?: string | null; review_notes?: string | null
          review_due_at?: string | null; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['interview_patterns']['Insert']>
        Relationships: []
      }

      readiness_dimension_scores: {
        Row: {
          id: string
          user_id: string
          dimension: 'aptitude_reasoning' | 'coding_problem_solving' | 'core_computer_science' | 'communication_interview' | 'assessment_performance' | 'portfolio_project'
          score: number
          confidence: 'low' | 'medium' | 'high'
          evidence_count: number
          evidence_fresh_at: string | null
          algorithm_version: string
          evidence: unknown
          computed_at: string
        }
        Insert: Omit<Database['public']['Tables']['readiness_dimension_scores']['Row'], 'id' | 'confidence' | 'evidence_count' | 'evidence_fresh_at' | 'algorithm_version' | 'evidence' | 'computed_at'> & {
          id?: string; confidence?: 'low' | 'medium' | 'high'; evidence_count?: number
          evidence_fresh_at?: string | null; algorithm_version?: string; evidence?: unknown; computed_at?: string
        }
        Update: Partial<Database['public']['Tables']['readiness_dimension_scores']['Insert']>
        Relationships: []
      }

      mentorship_requests: {
        Row: {
          id: string
          requester_id: string
          mentor_id: string | null
          topic: string
          context: string
          preferred_response: 'async' | 'call' | 'in_person'
          status: 'requested' | 'accepted' | 'answered' | 'declined' | 'redirected' | 'cancelled'
          resolution_note: string | null
          resolved_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['mentorship_requests']['Row'], 'id' | 'mentor_id' | 'preferred_response' | 'status' | 'resolution_note' | 'resolved_at' | 'created_at' | 'updated_at'> & {
          id?: string; mentor_id?: string | null; preferred_response?: 'async' | 'call' | 'in_person'
          status?: 'requested' | 'accepted' | 'answered' | 'declined' | 'redirected' | 'cancelled'
          resolution_note?: string | null; resolved_at?: string | null; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['mentorship_requests']['Insert']>
        Relationships: []
      }

      support_cases: {
        Row: {
          id: string
          student_id: string
          case_type: 'student_request' | 'evidence_gap' | 'assessment_support' | 'academic_continuity' | 'identity' | 'privacy' | 'technical'
          title: string
          context: string
          status: 'suggested' | 'requested' | 'active' | 'review_due' | 'resolved' | 'closed'
          owner_id: string | null
          goal: string | null
          action_plan: unknown
          review_at: string | null
          resolution: string | null
          privacy_level: 'faculty_student' | 'governance'
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['support_cases']['Row'], 'id' | 'status' | 'owner_id' | 'goal' | 'action_plan' | 'review_at' | 'resolution' | 'privacy_level' | 'created_at' | 'updated_at'> & {
          id?: string; status?: 'suggested' | 'requested' | 'active' | 'review_due' | 'resolved' | 'closed'
          owner_id?: string | null; goal?: string | null; action_plan?: unknown; review_at?: string | null
          resolution?: string | null; privacy_level?: 'faculty_student' | 'governance'; created_at?: string; updated_at?: string
        }
        Update: Partial<Database['public']['Tables']['support_cases']['Insert']>
        Relationships: []
      }

      current_readiness_scores: {
        Row: {
          user_id:         string
          score:           number
          components_json: Record<string, unknown> | null
          computed_at:     string
        }
        Insert: Database['public']['Tables']['current_readiness_scores']['Row']
        Update: Partial<Database['public']['Tables']['current_readiness_scores']['Row']>
        Relationships: []
      }

    }

    Views: {
      [_ in never]: never
    }

    // NOTE: existence of these RPCs is only partially verified. A blind
    // no-args probe returned 404 for most of them, but that test is
    // inconclusive for functions that require arguments (confirmed by
    // update_leetcode_username_unified, which DOES exist live with args —
    // the same blind probe also 404'd for it). Treat any function below
    // NOT marked "confirmed live" as unverified, not proven absent.
    Functions: {
      current_user_id:                     { Args: Record<string, never>; Returns: string }
      get_my_profile:                      { Args: Record<string, never>; Returns: Database['public']['Tables']['users']['Row'][] }
      get_user_team_uuid:                  { Args: { p_user_id: string }; Returns: string | null }
      assign_team_member:                  { Args: { p_user_id: string; p_team_id: string }; Returns: void }
      set_team_leader:                     { Args: { p_team_id: string; p_user_id: string }; Returns: void }
      set_member_permissions:              { Args: { p_user_id: string; p_permissions: string[] }; Returns: void }
      get_question_bank_full:              { Args: Record<string, never>; Returns: Database['public']['Tables']['question_bank']['Row'][] }
      update_leetcode_username_unified: { Args: { p_user_id: string; p_new_username: string }; Returns: Record<string, unknown> } // confirmed live
      set_ecampus_password:             { Args: { p_password: string | null }; Returns: void } // added in 08_security_fixes_sprint0.sql
      send_birthday_notifications:      { Args: Record<string, never>; Returns: number } // added in 09_sprint1_schema_and_features.sql
      knowledge_semantic_search: { // added in 09_sprint1_schema_and_features.sql
        Args: { query_embedding: number[]; match_threshold?: number; match_count?: number }
        Returns: Array<{ id: string; article_id: string; chunk_text: string; title: string; similarity: number }>
      }
      // Unverified — present in the never-applied supabase/migrations/02_functions.sql:
      get_user_role:                      { Args: { p_user_id: string }; Returns: { role: string; app_role: string }[] }
      get_batch_for_user:                 { Args: { p_user_id: string }; Returns: string }
      compute_readiness_score:            { Args: { p_user_id: string }; Returns: Record<string, unknown> }
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
    }
  }
}
