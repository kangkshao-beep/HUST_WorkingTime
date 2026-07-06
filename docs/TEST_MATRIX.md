# Test Matrix

| Case | Setup | Action | Expected Result | Actual Result | Pass/Fail |
| --- | --- | --- | --- | --- | --- |
| 1. Monday, no punch | Fixed Monday workday | Open Today | Shows workday, no record, clock-in CTAs | Not run: Xcode unavailable | Pending |
| 2. Monday, punch now | Fixed Monday workday | Tap now clock-in | Creates one record, target end is +8h | Not run: Xcode unavailable | Pending |
| 3. Manual punch earlier today | Workday, no record | Select earlier time and save | Record uses selected clock-in, no future time allowed | Not run: Xcode unavailable | Pending |
| 4. Countdown crosses relaunch | Existing record | Relaunch app later | Remaining time recalculates from targetEndAt | Package test covers core | Pending app run |
| 5. Countdown reaches zero | Existing record after target | Open app/widget | Shows target reached/completed state | Package test covers core | Pending app run |
| 6. Saturday | Fixed Saturday | Open Today | Shows rest day and excludes from month denominator | Package test covers core | Pending app run |
| 7. Month threshold exactly reached | Valid days equals required | Open Month | Month passed true | Package test covers core | Pending app run |
| 8. Month threshold not reached | Valid days below required | Open Month | Month passed false, remaining needed shown | Package test covers core | Pending app run |
| 9. Duplicate same-day record | Two records same dayKey | Calculate month | Counts one canonical record | Package test covers core | Pending app run |
| 10. iPhone offline -> later sync | Device offline | Clock in, later online | Local works, CloudKit catches up | Not run: device required | Pending |
| 11. Watch offline -> later sync | Watch offline | Clock in on watch | Local-first update, queued sync | Not implemented yet | Pending |
| 12. Mac receives CloudKit update | Mac signed in | Sync iPhone record | Mac app shows same record | Not implemented yet | Pending |
| 13. iPhone widget before/after punch | Widget added | Clock in | Snapshot updates widget state | Pending Xcode | Pending |
| 14. Mac desktop widget | Mac target configured | Add widget | Shows same rules from local snapshot | Not implemented yet | Pending |
| 15. Watch complication | Watch target configured | Add complication | Shows active countdown/status | Not implemented yet | Pending |
