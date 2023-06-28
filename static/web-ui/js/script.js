document.addEventListener(
  "readystatechange",
  () => {
    const treeRoot = document.querySelector('[title="::"]');
    if (treeRoot) {
      setTimeout(() => {
        treeRoot.click();
      }, 1000);
    }

    const container = document.querySelector("#container");

    const observer = new MutationObserver(function () {
      const pagination = container.querySelector(".pagination");

      if (!pagination) {
        return;
      }

      if (pagination.children.length < 4) {
        pagination.style.display = "none";
      } else {
        pagination.style.display = "inline-block";
      }
    });

    const config = {
      attributes: true,
      childList: true,
      characterData: true,
      subtree: true,
    };

    observer.observe(container, config);
  },
  false
);
