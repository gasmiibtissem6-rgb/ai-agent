import * as Icons from "../icons";

export const NAV_DATA = [
  {
    label: "OVERVIEW",
    items: [
      {
        title: "Dashboard",
        icon: Icons.HomeIcon,
        items: [
          {
            title: "Overview",
            url: "/",
          },
        ],
      },
    ],
  },
  {
    label: "IDENTITY & SAFETY",
    items: [
      {
        title: "User Management",
        icon: Icons.User,
        items: [
          {
            title: "User Directory",
            url: "/admin/users",
          },
          {
            title: "KYC Review Queue",
            url: "/admin/kyc",
          },
        ],
      },
    ],
  },
  {
    label: "BUSINESS OPERATIONS",
    items: [
      {
        title: "Deal Management",
        icon: Icons.Table,
        items: [
          {
            title: "Deals Ledger",
            url: "/admin/deals",
          },
          {
            title: "Contract Archive",
            url: "/admin/contract-archive",
          },
        ],
      },
      {
        title: "Dispute Center",
        icon: Icons.FourCircle,
        items: [
          {
            title: "Ticket Queue",
            url: "/admin/dispute-center",
          },
        ],
      },
    ],
  },
  {
    label: "ACCOUNT",
    items: [
      {
        title: "Profile",
        url: "/profile",
        icon: Icons.User,
        items: [],
      },
      {
        title: "Settings",
        icon: Icons.Alphabet,
        items: [
          {
            title: "Account Settings",
            url: "/pages/settings",
          },
        ],
      },
    ],
  },
];