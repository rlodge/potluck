"use client";

import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import Link from "next/link";

const GUEST_STORAGE_KEY = "potluck-guest";

interface GuestIdentity {
  name: string;
  email: string;
}

export function getStoredGuestIdentity(): GuestIdentity | null {
  if (typeof window === "undefined") return null;
  try {
    const stored = localStorage.getItem(GUEST_STORAGE_KEY);
    return stored ? JSON.parse(stored) : null;
  } catch {
    return null;
  }
}

function storeGuestIdentity(identity: GuestIdentity) {
  localStorage.setItem(GUEST_STORAGE_KEY, JSON.stringify(identity));
}

interface GuestIdentityModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (name: string, email: string, count: number) => void;
  /** False when the caller is already an authenticated user — skips the name/email fields and only asks for party size. */
  requireIdentity?: boolean;
}

export function GuestIdentityModal({
  open,
  onClose,
  onSubmit,
  requireIdentity = true,
}: GuestIdentityModalProps) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [count, setCount] = useState(1);

  useEffect(() => {
    if (!open) return;
    setCount(1);
    if (requireIdentity) {
      const stored = getStoredGuestIdentity();
      if (stored) {
        setName(stored.name);
        setEmail(stored.email);
      }
    }
  }, [open, requireIdentity]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (requireIdentity) {
      if (!name.trim()) return;
      storeGuestIdentity({ name: name.trim(), email: email.trim() });
    }
    onSubmit(name.trim(), email.trim(), count);
  };

  const canSubmit = requireIdentity ? !!name.trim() : true;

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>
            {requireIdentity ? "What's your name?" : "How many are coming?"}
          </DialogTitle>
          <DialogDescription>
            {requireIdentity
              ? "So everyone knows who's bringing what."
              : "Let the host know your party size."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          {requireIdentity && (
            <>
              <div className="space-y-2">
                <Label htmlFor="guest-name">Display name *</Label>
                <Input
                  id="guest-name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Your name"
                  autoFocus
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="guest-email">
                  Email <span className="text-muted-foreground">(optional)</span>
                </Label>
                <Input
                  id="guest-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                />
                <p className="text-xs text-muted-foreground">
                  For notifications if the host verifies your contribution.
                </p>
              </div>
            </>
          )}
          <div className="space-y-2">
            <Label htmlFor="guest-count">
              How many are coming?{" "}
              <span className="text-muted-foreground">(including you)</span>
            </Label>
            <Input
              id="guest-count"
              type="number"
              inputMode="numeric"
              min={1}
              max={99}
              value={count}
              autoFocus={!requireIdentity}
              onChange={(e) => {
                const parsed = parseInt(e.target.value, 10);
                setCount(Number.isFinite(parsed) ? Math.min(99, Math.max(1, parsed)) : 1);
              }}
            />
          </div>
          <DialogFooter className="flex-col gap-2 sm:flex-col">
            <Button type="submit" disabled={!canSubmit} className="w-full">
              {requireIdentity ? "Continue" : "RSVP"}
            </Button>
            {requireIdentity && (
              <p className="text-xs text-center text-muted-foreground">
                Want to earn points?{" "}
                <Link href="/auth/login" className="text-primary underline">
                  Create an account
                </Link>
              </p>
            )}
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
