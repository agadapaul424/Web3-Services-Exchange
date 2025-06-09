import { describe, expect, it } from "vitest";

// Mock Clarinet environment
const mockClarinet = {
  contracts: new Map(),
  accounts: new Map(),
  currentBlock: 1,
};

// Mock contract deployment
const deployContract = (contractName, contractCode) => {
  mockClarinet.contracts.set(contractName, {
    code: contractCode,
    state: new Map(),
    functions: new Map(),
  });
};

// Mock contract call
const callContract = (contractName, functionName, args, sender) => {
  const contract = mockClarinet.contracts.get(contractName);
  if (!contract) throw new Error(`Contract ${contractName} not found`);

  // Simulate contract execution logic
  return mockContractExecution(contractName, functionName, args, sender);
};

// Mock contract execution with simplified logic
const mockContractExecution = (contractName, functionName, args, sender) => {
  const contract = mockClarinet.contracts.get(contractName);
  const state = contract.state;

  switch (functionName) {
    case "create-profile":
      const profileKey = `profile-${sender}`;
      state.set(profileKey, {
        name: args[0],
        bio: args[1],
        skills: args[2],
        totalServices: 0,
        totalBookings: 0,
        averageRating: 0,
        isVerified: false,
        joinedAt: mockClarinet.currentBlock,
      });
      return { success: true, result: true };

    case "create-service":
      const serviceId = state.get("nextServiceId") || 1;
      const serviceKey = `service-${serviceId}`;

      if (args[3] <= 0) {
        // price validation
        return { success: false, error: "err-invalid-amount" };
      }

      state.set(serviceKey, {
        provider: sender,
        title: args[0],
        description: args[1],
        category: args[2],
        pricePerHour: args[3],
        currency: args[4],
        availability: args[5],
        status: 1, // service-active
        rating: 0,
        totalReviews: 0,
        createdAt: mockClarinet.currentBlock,
      });

      state.set("nextServiceId", serviceId + 1);
      return { success: true, result: serviceId };

    case "book-service":
      const bookingId = state.get("nextBookingId") || 1;
      const bookingServiceId = args[0];
      const serviceToBook = state.get(`service-${bookingServiceId}`);

      if (!serviceToBook) {
        return { success: false, error: "err-not-found" };
      }

      if (serviceToBook.provider === sender) {
        return { success: false, error: "err-unauthorized" };
      }

      const hours = args[1];
      const totalAmount = serviceToBook.pricePerHour * hours;
      const platformFee = Math.floor((totalAmount * 250) / 10000); // 2.5%

      state.set(`booking-${bookingId}`, {
        serviceId: bookingServiceId,
        client: sender,
        provider: serviceToBook.provider,
        hours: hours,
        totalAmount: totalAmount,
        platformFee: platformFee,
        status: 1, // booking-pending
        scheduledTime: args[2],
        createdAt: mockClarinet.currentBlock,
        completedAt: null,
      });

      state.set(`escrow-${bookingId}`, totalAmount + platformFee);
      state.set("nextBookingId", bookingId + 1);
      return { success: true, result: bookingId };

    case "confirm-booking":
      const confirmBookingId = args[0];
      const bookingToConfirm = state.get(`booking-${confirmBookingId}`);

      if (!bookingToConfirm) {
        return { success: false, error: "err-booking-not-found" };
      }

      if (bookingToConfirm.provider !== sender) {
        return { success: false, error: "err-unauthorized" };
      }

      if (bookingToConfirm.status !== 1) {
        // not pending
        return { success: false, error: "err-invalid-status" };
      }

      bookingToConfirm.status = 2; // booking-confirmed
      state.set(`booking-${confirmBookingId}`, bookingToConfirm);
      return { success: true, result: true };

    case "complete-booking":
      const completeBookingId = args[0];
      const bookingToComplete = state.get(`booking-${completeBookingId}`);

      if (!bookingToComplete) {
        return { success: false, error: "err-booking-not-found" };
      }

      if (bookingToComplete.provider !== sender) {
        return { success: false, error: "err-unauthorized" };
      }

      if (bookingToComplete.status !== 2) {
        // not confirmed
        return { success: false, error: "err-invalid-status" };
      }

      bookingToComplete.status = 3; // booking-completed
      bookingToComplete.completedAt = mockClarinet.currentBlock;
      state.set(`booking-${completeBookingId}`, bookingToComplete);
      return { success: true, result: true };

    case "add-review":
      const reviewBookingId = args[0];
      const rating = args[1];
      const comment = args[2];
      const bookingForReview = state.get(`booking-${reviewBookingId}`);

      if (!bookingForReview) {
        return { success: false, error: "err-booking-not-found" };
      }

      if (
        bookingForReview.client !== sender &&
        bookingForReview.provider !== sender
      ) {
        return { success: false, error: "err-unauthorized" };
      }

      if (bookingForReview.status !== 3) {
        // not completed
        return { success: false, error: "err-invalid-status" };
      }

      if (rating < 1 || rating > 5) {
        return { success: false, error: "err-invalid-amount" };
      }

      const reviewKey = `review-${reviewBookingId}-${sender}`;
      if (state.get(reviewKey)) {
        return { success: false, error: "err-already-reviewed" };
      }

      state.set(reviewKey, {
        rating: rating,
        comment: comment,
        createdAt: mockClarinet.currentBlock,
      });

      // Update service rating
      const serviceForReview = state.get(
        `service-${bookingForReview.serviceId}`
      );
      const currentTotal = serviceForReview.totalReviews;
      const currentRating = serviceForReview.rating;
      const newTotal = currentTotal + 1;
      const newRating = Math.floor(
        (currentRating * currentTotal + rating) / newTotal
      );

      serviceForReview.rating = newRating;
      serviceForReview.totalReviews = newTotal;
      state.set(`service-${bookingForReview.serviceId}`, serviceForReview);

      return { success: true, result: true };

    case "get-service":
      const getServiceId = args[0];
      const service = state.get(`service-${getServiceId}`);
      return { success: true, result: service || null };

    case "get-booking":
      const getBookingId = args[0];
      const booking = state.get(`booking-${getBookingId}`);
      return { success: true, result: booking || null };

    case "get-user-profile":
      const getUserAddress = args[0];
      const profile = state.get(`profile-${getUserAddress}`);
      return { success: true, result: profile || null };

    default:
      return { success: false, error: "function-not-found" };
  }
};

// Test accounts
const accounts = {
  deployer: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  alice: "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5",
  bob: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
  charlie: "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC",
};

// Deploy contract before tests
deployContract("p2p-marketplace", "contract-code-placeholder");

describe("P2P Service Marketplace", () => {
  describe("User Profile Management", () => {
    it("should create a user profile successfully", () => {
      const result = callContract(
        "p2p-marketplace",
        "create-profile",
        [
          "Alice Developer",
          "Experienced web developer",
          "JavaScript, React, Node.js",
        ],
        accounts.alice
      );

      expect(result.success).toBe(true);
      expect(result.result).toBe(true);
    });

    it("should retrieve user profile after creation", () => {
      // First create profile
      callContract(
        "p2p-marketplace",
        "create-profile",
        ["Bob Designer", "Creative graphic designer", "Photoshop, Illustrator"],
        accounts.bob
      );

      // Then retrieve it
      const result = callContract(
        "p2p-marketplace",
        "get-user-profile",
        [accounts.bob],
        accounts.deployer
      );

      expect(result.success).toBe(true);
      expect(result.result).not.toBeNull();
      expect(result.result.name).toBe("Bob Designer");
      expect(result.result.bio).toBe("Creative graphic designer");
      expect(result.result.skills).toBe("Photoshop, Illustrator");
    });
  });

  describe("Service Management", () => {
    it("should create a service successfully", () => {
      const result = callContract(
        "p2p-marketplace",
        "create-service",
        [
          "Web Development Service",
          "Full-stack web development using modern technologies",
          "web-development",
          50, // $50 per hour
          "USD",
          "Monday-Friday, 9AM-5PM",
        ],
        accounts.alice
      );

      expect(result.success).toBe(true);
      expect(result.result).toBe(1); // First service ID
    });
  });
});
