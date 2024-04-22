/// <reference types="vite/client" />

type Branch = {
  name: string;
  date: string;
};

type ViewState = {
  [project: string]: {
    [branch: string]: Branch;
  };
};
