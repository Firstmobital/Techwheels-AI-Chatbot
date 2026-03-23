import { Navigate, Route, Routes } from "react-router-dom";
import { RequireAuth } from "./components/auth/RequireAuth";
import { AppLayout } from "./components/layout/AppLayout";
import { AnalyticsPage } from "./pages/AnalyticsPage";
import { CampaignSenderPage } from "./pages/CampaignSenderPage";
import { ConversationPage } from "./pages/ConversationPage";
import { LeadDetailPage } from "./pages/LeadDetailPage";
import { LeadsPage } from "./pages/LeadsPage";
import { LoginPage } from "./pages/LoginPage";
import { VariantsPricingAdminPage } from "./pages/VariantsPricingAdminPage";

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="*"
        element={
          <RequireAuth>
            <AppLayout>
              <Routes>
                <Route path="/" element={<Navigate to="/leads" replace />} />
                <Route path="/leads" element={<LeadsPage />} />
                <Route path="/leads/:leadId" element={<LeadDetailPage />} />
                <Route
                  path="/conversations/:conversationId"
                  element={<ConversationPage />}
                />
                <Route
                  path="/admin/variants-pricing"
                  element={<VariantsPricingAdminPage />}
                />
                <Route path="/analytics" element={<AnalyticsPage />} />
                <Route path="/campaigns" element={<CampaignSenderPage />} />
              </Routes>
            </AppLayout>
          </RequireAuth>
        }
      />
    </Routes>
  );
}
