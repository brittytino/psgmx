'use client';

import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import ConfirmationModal, { ConfirmationOptions } from '@/components/basic/confirmation-modal';
import { AnimatePresence, motion } from 'framer-motion';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

interface ToastState {
  id: number;
  message: string;
  type: 'success' | 'error' | 'info';
}

interface UIContextType {
  confirm: (options: ConfirmationOptions) => Promise<boolean>;
  showToast: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const UIContext = createContext<UIContextType | undefined>(undefined);

export function UIProvider({ children }: { children: ReactNode }) {
  const [confirmOptions, setConfirmOptions] = useState<ConfirmationOptions | null>(null);
  const [confirmPromise, setConfirmPromise] = useState<{ resolve: (value: boolean) => void } | null>(null);
  const [toast, setToast] = useState<ToastState | null>(null);

  const confirm = useCallback((options: ConfirmationOptions): Promise<boolean> => {
    setConfirmOptions(options);
    return new Promise((resolve) => {
      setConfirmPromise({ resolve });
    });
  }, []);

  const handleConfirm = useCallback((value: boolean) => {
    if (confirmPromise) {
      confirmPromise.resolve(value);
    }
    setConfirmOptions(null);
    setConfirmPromise(null);
  }, [confirmPromise]);

  const showToast = useCallback((message: string, type: 'success' | 'error' | 'info' = 'success') => {
    const id = Date.now();
    setToast({ id, message, type });
    setTimeout(() => {
      setToast((current) => (current?.id === id ? null : current));
    }, 4500);
  }, []);

  return (
    <UIContext.Provider value={{ confirm, showToast }}>
      {children}

      {/* Global Confirmation Modal */}
      <AnimatePresence>
        {confirmOptions && (
          <ConfirmationModal
            isOpen={true}
            onClose={() => handleConfirm(false)}
            onConfirm={() => handleConfirm(true)}
            {...confirmOptions}
          />
        )}
      </AnimatePresence>

      {/* Global Toast System */}
      <AnimatePresence>
        {toast && (
          <motion.div
            key={toast.id}
            initial={{ opacity: 0, y: -24, scale: 0.95, x: '-50%' }}
            animate={{ opacity: 1, y: 0, scale: 1, x: '-50%' }}
            exit={{ opacity: 0, y: -16, scale: 0.95, x: '-50%' }}
            transition={{ type: 'spring', damping: 26, stiffness: 350 }}
            className="fixed top-6 left-1/2 z-[200] max-w-[92vw] sm:max-w-md w-max pointer-events-auto"
          >
            <div className="flex items-center gap-3 px-4 py-3 rounded-2xl bg-[#101828]/95 backdrop-blur-xl border border-white/15 text-white shadow-[0_20px_50px_rgba(16,24,40,0.35)]">
              {toast.type === 'success' && (
                <div className="grid h-7 w-7 shrink-0 place-items-center rounded-xl bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  <CheckCircle2 className="h-4 w-4" />
                </div>
              )}
              {toast.type === 'error' && (
                <div className="grid h-7 w-7 shrink-0 place-items-center rounded-xl bg-rose-500/20 text-rose-400 border border-rose-500/30">
                  <AlertCircle className="h-4 w-4" />
                </div>
              )}
              {toast.type === 'info' && (
                <div className="grid h-7 w-7 shrink-0 place-items-center rounded-xl bg-[#FF5A1F]/20 text-[#FF5A1F] border border-[#FF5A1F]/30">
                  <Info className="h-4 w-4" />
                </div>
              )}
              <p className="text-[13px] font-medium leading-relaxed text-zinc-100 pr-1">
                {toast.message}
              </p>
              <button
                type="button"
                onClick={() => setToast(null)}
                aria-label="Close notification"
                className="ml-auto -mr-1 p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-white/10 transition"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </UIContext.Provider>
  );
}

export function useUI() {
  const context = useContext(UIContext);
  if (context === undefined) {
    throw new Error('useUI must be used within a UIProvider');
  }
  return context;
}
