export type fetchAction =
  // @ts-ignore should add a generic here
  | { type: "FETCH_COMPLETE"; payload: any } // eslint-disable-line
  | { type: "FETCH_ERROR" }
  | { type: "FETCH_STARTED" };

export interface State {
  data: any | null;
  isLoading: boolean;
  error: boolean;
}

export const reducer = (state: State, action: fetchAction): State => {
  switch (action.type) {
    case "FETCH_STARTED":
      return { ...state, isLoading: true, error: false, data: null };
    case "FETCH_COMPLETE":
      return { ...state, data: action.payload, isLoading: false, error: false };
    case "FETCH_ERROR":
      return { ...state, error: true, isLoading: false };
    default:
      return state;
  }
};
