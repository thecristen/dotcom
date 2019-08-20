import {
  serviceDays,
  serviceDate,
  groupServiceByDate,
  groupByType,
  ServicesKeyedByGroup,
  ServiceByOptGroup,
  getTodaysSchedule
} from "../service";
import { Service, ServiceWithServiceDate, DayInteger } from "../../__v3api";

const service: Service = {
  added_dates: [],
  added_dates_notes: {},
  description: "Weekday schedule",
  end_date: "2019-06-25",
  id: "BUS319-D-Wdy-02",
  removed_dates: [],
  removed_dates_notes: {},
  start_date: "2019-06-25",
  type: "weekday",
  typicality: "typical_service",
  valid_days: [1, 2, 3, 4, 5],
  name: "weekday"
};

const serviceWithDate: ServiceWithServiceDate = {
  added_dates: [],
  added_dates_notes: {},
  description: "Weekday schedule",
  end_date: "2019-06-25",
  id: "BUS319-D-Wdy-02",
  removed_dates: [],
  removed_dates_notes: {},
  start_date: "2019-06-25",
  type: "weekday",
  typicality: "typical_service",
  valid_days: [1, 2, 3, 4, 5],
  service_date: "2019-06-25",
  name: "weekday"
};

describe("serviceDays", () => {
  it("returns an empty string for weekends", () => {
    const saturday: Service = {
      ...service,
      description: "Saturday schedule",
      type: "saturday",
      valid_days: [6]
    };
    expect(serviceDays(saturday)).toBe("");

    const sunday: Service = {
      ...service,
      description: "Sunday schedule",
      type: "sunday",
      valid_days: [7]
    };
    expect(serviceDays(sunday)).toBe("");
  });

  it("returns a single day in parentheses", () => {
    const friday: Service = { ...service, valid_days: [5] };
    expect(serviceDays(friday)).toBe("Friday");
  });

  it("returns consecutive days as Monday - Friday", () => {
    expect(serviceDays(service)).toBe("Monday - Friday");
    const monToWed: Service = { ...service, valid_days: [1, 2, 3] };
    expect(serviceDays(monToWed)).toBe("Monday - Wednesday");

    const wedToFri: Service = { ...service, valid_days: [3, 4, 5] };
    expect(serviceDays(wedToFri)).toBe("Wednesday - Friday");
  });

  it("lists all non-consecutive days", () => {
    const monWedFri: Service = { ...service, valid_days: [1, 3, 5] };
    expect(serviceDays(monWedFri)).toBe("Monday, Wednesday, Friday");
  });
});

const currentService = {
  ...serviceWithDate,
  start_date: "2019-06-25",
  end_date: "2019-07-28"
};
const upcomingService = {
  ...serviceWithDate,
  start_date: "2019-07-01",
  end_date: "2019-07-30"
};

describe("serviceDate", () => {
  it("handles holidays", () => {
    const date = serviceDate(service);
    expect(date).toBe("on June 25");
  });

  it("handles current schedules", () => {
    const date = serviceDate(currentService);
    expect(date).toBe("ends July 28");
  });

  it("handles upcoming schedules", () => {
    const date = serviceDate(upcomingService);
    expect(date).toBe("starts July 1");
  });

  it("handles a range of dates when service date is not provided", () => {
    const date = serviceDate({ ...service, end_date: "2019-07-04" });
    expect(date).toBe("June 25 to July 4");
  });
});

describe("groupServiceByDate", () => {
  it("groups current schedules with the proper service period", () => {
    const groupedService = groupServiceByDate(currentService);
    expect(groupedService).toEqual({
      type: "current",
      servicePeriod: "ends July 28",
      service: currentService
    });
  });

  it("groups upcoming schedules as future with proper service period", () => {
    const groupedService = groupServiceByDate(upcomingService);
    expect(groupedService).toEqual({
      type: "future",
      servicePeriod: "starts July 1",
      service: upcomingService
    });
  });

  it("groups holiday schedules with proper service period", () => {
    const groupedService = groupServiceByDate({
      ...service,
      service_date: "06-25-19",
      typicality: "holiday_service"
    });
    expect(groupedService).toEqual({
      type: "holiday",
      servicePeriod: "on June 25",
      service: { ...service, service_date: "06-25-19", typicality: "holiday_service" }
    });
  });
  it("marks future schedules as future", () => {
    const groupedService = groupServiceByDate({
      ...currentService,
      start_date: "2019-01-01",
      end_date: "2019-01-02"
    });
    expect(groupedService).toEqual({
      type: "future",
      servicePeriod: "January 1 to January 2",
      service: {
        ...currentService,
        start_date: "2019-01-01",
        end_date: "2019-01-02"
      }
    });
  });
});

const groupServices = (services: ServiceWithServiceDate[]) =>
  services
    .map((service: ServiceWithServiceDate) => groupServiceByDate(service))
    .reduce(
      (acc: ServicesKeyedByGroup, currService: ServiceByOptGroup) =>
        groupByType(acc, currService),
      { future: [], current: [], holiday: [] }
    );

const holidayService = { ...service, service_date: "2019-06-25" };

describe("getTodaysSchedule", () => {
  it("marks the holiday day as today if there is a holiday", () => {
    const today = getTodaysSchedule(
      groupServices([
        {
          ...currentService,
          start_date: "2019-06-24",
          service_date: "2019-06-25",
          typicality: "holiday_service"
        },
        { ...upcomingService, service_date: "2019-06-25" },
        holidayService
      ])
    );
    expect(today!.service).toEqual(holidayService);
  });

  it("marks the current schedule as today if the day of the week is correct", () => {
    const sunday: DayInteger = 7;
    const sundayService = {
      ...service,
      valid_days: [sunday],
      service_date: "2019-06-30",
      end_date: "2019-07-28"
    };
    const today = getTodaysSchedule(
      groupServices([{ ...service, service_date: "2019-06-30" }, sundayService])
    );

    expect(today!.service).toEqual(sundayService);
  });
});
