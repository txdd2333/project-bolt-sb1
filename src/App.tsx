import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Layout from './components/Layout'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import ModulesPage from './pages/ModulesPage'
import WorkflowsPage from './pages/WorkflowsPage'
import WorkflowEditorPage from './pages/WorkflowEditorPage'
import ScenariosPage from './pages/ScenariosPage'
import ScenarioDetailPage from './pages/ScenarioDetailPage'
import ExecutionLogsPage from './pages/ExecutionLogsPage'

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/scenarios" replace />} />
            <Route path="modules" element={<ModulesPage />} />
            <Route path="workflows" element={<WorkflowsPage />} />
            <Route path="workflows/:id" element={<WorkflowEditorPage />} />
            <Route path="scenarios" element={<ScenariosPage />} />
            <Route path="scenarios/:id" element={<ScenarioDetailPage />} />
            <Route path="logs" element={<ExecutionLogsPage />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
