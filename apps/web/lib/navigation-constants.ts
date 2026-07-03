import { 
  LayoutDashboard, 
  ClipboardList, 
  Building2, 
  Users, 
  ClipboardCheck, 
  BarChart3, 
  Activity,
  UserPlus, 
  PlusCircle,
  ListTodo,
  Calendar
} from 'lucide-react';
import React from 'react';
export interface SidebarItem {
  icon: React.ElementType;
  label: string;
  href?: string;
  tab?: string;
  active?: boolean;
}

export const ADMIN_SIDEBAR_ITEMS: SidebarItem[] = [
  {
    label: 'Dashboard',
    icon: LayoutDashboard,
    tab: 'overview',
  },
  {
    label: 'PRI Test Builder',
    icon: ClipboardList,
    href: '/admin/pri-test',
  },
  {
    label: 'Assessments',
    icon: Building2,
    tab: 'institutions',
  },
  {
    label: 'PRI Management',
    icon: ClipboardList,
    tab: 'pri-tests',
  },
  {
    label: 'Contributors',
    icon: Users,
    tab: 'contributors',
  },
  {
    label: 'Review Contributions',
    icon: ClipboardCheck,
    tab: 'review',
  },
];

export const FACULTY_SIDEBAR_ITEMS: SidebarItem[] = [
  {
    label: 'Overview Feed',
    icon: LayoutDashboard,
    tab: 'overview',
  },
  {
    label: 'Candidates',
    icon: Activity,
    tab: 'students',
  },
  {
    label: 'Batch Insights',
    icon: BarChart3,
    tab: 'batch-insights',
  },
];

export const INSTITUTION_ADMIN_SIDEBAR_ITEMS: SidebarItem[] = [
  {
    label: 'Overview Feed',
    icon: LayoutDashboard,
    tab: 'overview',
  },
  {
    label: 'Batches',
    icon: Users,
    tab: 'batches',
  },
  {
    label: 'Batch Insights',
    icon: BarChart3,
    tab: 'batch-insights',
  },
  {
    label: 'Sessions',
    icon: Calendar,
    tab: 'fri-tests',
  },
  {
    label: 'Trainers',
    icon: Users,
    tab: 'faculty',
  },
  {
    label: 'Candidates',
    icon: UserPlus,
    tab: 'student',
  },
];

export const STUDENT_SIDEBAR_ITEMS: SidebarItem[] = [
  {
    label: 'Dashboard',
    icon: LayoutDashboard,
    tab: 'dashboard',
  },
  {
    label: 'Assessments',
    icon: ClipboardList,
    tab: 'assessments',
  },
  {
    label: 'Reports',
    icon: BarChart3,
    tab: 'results',
  },
];

export const CONTRIBUTOR_SIDEBAR_ITEMS: SidebarItem[] = [
  {
    label: 'Add Question',
    icon: PlusCircle,
    tab: 'categories',
  },
  {
    label: 'My Submissions',
    icon: ListTodo,
    tab: 'submissions',
  },
];
