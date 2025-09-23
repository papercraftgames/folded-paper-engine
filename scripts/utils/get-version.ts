export type VersionInfo = {
  major: number;
  minor: number;
  patch: number;
};

export const getVersion = (): string => {
  const v = process.env.VERSION ?? "1.0.0";

  return v.replace(/[a-zA-Z]/gmi, "");
};

export const getVersionInfo = (): VersionInfo => {
  const v = getVersion();
  const [major, minor, patch] = v.split(".");
  const majorClean: string = major.replace(/[a-zA-Z]/gmi, "");
  const minorClean: string = minor.replace(/[a-zA-Z]/gmi, "");
  const patchClean: string = patch.replace(/[a-zA-Z]/gmi, "");
  const majorInt = parseInt(majorClean);
  const minorInt = parseInt(minorClean);
  const patchInt = parseInt(patchClean);

  return {
    major: majorInt,
    minor: minorInt,
    patch: patchInt,
  };
};
