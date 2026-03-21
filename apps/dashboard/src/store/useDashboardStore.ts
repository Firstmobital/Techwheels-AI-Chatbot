import { create } from "zustand";

type DashboardState = {
  leadSearch: string;
  leadStatusFilter: string;
  selectedLeadId: string | null;
  setLeadSearch: (value: string) => void;
  setLeadStatusFilter: (value: string) => void;
  setSelectedLeadId: (value: string | null) => void;
};

export const useDashboardStore = create<DashboardState>((set) => ({
  leadSearch: "",
  leadStatusFilter: "all",
  selectedLeadId: null,
  setLeadSearch: (value) => set({ leadSearch: value }),
  setLeadStatusFilter: (value) => set({ leadStatusFilter: value }),
  setSelectedLeadId: (value) => set({ selectedLeadId: value }),
}));
