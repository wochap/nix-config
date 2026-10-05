import Quickshell
import qs.services

Scope {
  id: root

  LazyLoader {
    active: SAuth.current !== null
    component: AuthPromptContent {}
  }
}
