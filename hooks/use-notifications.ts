"use client";

import { useEffect, useCallback } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { useToast } from "@/components/ui/toast";

export function useNotifications() {
  const queryClient = useQueryClient();
  const { notify } = useToast();

  const getProfileName = useCallback(async (userId: string) => {
    try {
      const supabase = createClient();
      const { data } = await supabase
        .from("profiles")
        .select("full_name")
        .eq("user_id", userId)
        .single();
      
      return data?.full_name || "Seseorang";
    } catch (error) {
      console.error("Gagal mengambil profil:", error);
      return "Seseorang";
    }
  }, []);

  const showNotification = useCallback((title: string, body: string) => {
    // Show toast
    notify(title, body);

    // Show browser notification if permitted
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification(title, { body });
    }
  }, [notify]);

  useEffect(() => {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission();
    }

    const supabase = createClient();

    // Subscribe to Loans
    const loansChannel = supabase
      .channel('schema-db-changes-loans')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'loans',
        },
        async (payload) => {
          // Invalidate queries
          queryClient.invalidateQueries({ queryKey: ["loans"] });
          queryClient.invalidateQueries({ queryKey: ["admin", "loans"] });
          queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });

          if (payload.eventType === 'INSERT') {
            const name = await getProfileName(payload.new.borrower_id);
            showNotification("Peminjaman Baru", `${name} mengajukan peminjaman baru.`);
          } else if (payload.eventType === 'UPDATE') {
            const status = payload.new.status;
            const adminName = payload.new.admin_id ? await getProfileName(payload.new.admin_id) : "Admin";
            
            // Assuming status changed
            if (payload.old.status !== status) {
              if (status === "approved") {
                showNotification("Pinjaman Disetujui", `Pinjaman telah disetujui oleh ${adminName}.`);
              } else if (status === "rejected") {
                showNotification("Pinjaman Ditolak", `Pinjaman telah ditolak oleh ${adminName}.`);
              } else if (status === "returning") {
                const name = await getProfileName(payload.new.borrower_id);
                showNotification("Pengajuan Pengembalian", `${name} mengajukan pengembalian barang.`);
              } else if (status === "returned") {
                showNotification("Barang Dikembalikan", `Pengembalian barang dikonfirmasi oleh ${adminName}.`);
              }
            }
          }
        }
      )
      .subscribe();

    // Subscribe to Items
    const itemsChannel = supabase
      .channel('schema-db-changes-items')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'items',
        },
        async (payload) => {
          // Invalidate queries
          queryClient.invalidateQueries({ queryKey: ["catalog"] });
          queryClient.invalidateQueries({ queryKey: ["admin", "items"] });

          const adminName = payload.new.admin_id ? await getProfileName(payload.new.admin_id) : "Admin";
          showNotification("Barang Baru", `${adminName} menambahkan barang "${payload.new.name}" ke inventaris.`);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(loansChannel);
      supabase.removeChannel(itemsChannel);
    };
  }, [queryClient, getProfileName, showNotification]);
}
