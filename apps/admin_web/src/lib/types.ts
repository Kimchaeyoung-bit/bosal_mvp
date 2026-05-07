/// 어드민에서 자주 쓰는 도메인 타입. Supabase gen types 도입 시 대체 가능.

export type BosalRow = {
  id: string;
  slug: string | null;
  name: string;
  one_liner: string | null;
  description: string | null;
  experience_years: number;
  consult_style_id: string | null;
  phone_display: string | null;
  phone_e164: string | null;
  original_price: number;
  discounted_price: number;
  first_visit_price: number;
  max_points: number;
  sido: string | null;
  sigungu: string | null;
  eupmyeondong: string | null;
  road_address: string | null;
  region_id: string | null;
  sub_region_id: string | null;
  ad_intent_tier_id: string | null;
  rating_avg: number | string;
  review_count: number;
  consult_request_count: number;
  is_published: boolean;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
};

export type RegionRow = {
  id: string;
  code: string;
  name: string;
  sort_order: number;
};

export type SubRegionRow = {
  id: string;
  region_id: string;
  code: string;
  name: string;
  sort_order: number;
};

export type CategoryRow = {
  id: string;
  code: string;
  name: string;
  sort_order: number;
  is_active: boolean;
};

export type ConsultStyleRow = {
  id: string;
  code: string;
  label: string;
  sort_order: number;
};

export type AdIntentTierRow = {
  id: string;
  code: string;
  label: string;
  description: string | null;
  sort_order: number;
};

export type ProfileRow = {
  id: string;
  role: 'user' | 'bosal' | 'admin';
  display_name: string | null;
  bosal_id: string | null;
  avatar_url: string | null;
  created_at: string;
  deleted_at: string | null;
};

export type InviteSummaryRow = {
  code: string;
  bosal_id: string | null;
  bosal_name: string | null;
  email: string | null;
  expires_at: string | null;
  used_at: string | null;
  status: 'active' | 'used' | 'expired';
};

export type ReportRow = {
  id: string;
  reporter_id: string;
  target_kind: 'review' | 'bosal' | 'user';
  target_id: string;
  reason: string;
  description: string | null;
  status: 'pending' | 'resolved' | 'dismissed';
  resolved_by: string | null;
  resolved_at: string | null;
  resolution_note: string | null;
  created_at: string;
};
