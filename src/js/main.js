import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import vertex from "../shaders/vertex.glsl";
import fragment from "../shaders/fragment.glsl";
import GUI from "lil-gui";
import matcap from "../img/matcap.png";
import matcap2 from "../img/matcap1.png";

class WebGL {
  constructor() {
    //scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xffffff);

    //Renderer
    this.container = document.querySelector("main");
    this.renderer = new THREE.WebGLRenderer();
    this.container.appendChild(this.renderer.domElement);
    this.renderer.setPixelRatio(2);

    this.time = 0;
    //this.mouse;
    this.addCamera();
    this.addMesh();
    this.addControl();
    this.addLight();
    this.render();
    this.onWindowResize();
    this.settings();
    this.mouseEvent();
  }

  get viewport() {
    let width = window.innerWidth;
    let height = window.innerHeight;
    let aspectRatio = width / height;

    return {
      width,
      height,
      aspectRatio,
    };
  }

  mouseEvent() {
    this.mouse = new THREE.Vector2();
    document.addEventListener("mousemove", (e) => {
      this.mouse.x = e.pageX / this.viewport.width - 0.5;
      this.mouse.y = -e.pageY / this.viewport.height + 0.5;
    });
  }

  addCamera() {
    window.addEventListener("resize", this.onWindowResize.bind(this));
    var frustumSize = 1;
    this.camera = new THREE.OrthographicCamera(frustumSize / -2, frustumSize / 2, frustumSize / 2, frustumSize / -2, -1000, 1000);
    this.camera.position.set(0, 0, 1);

    // this.camera = new THREE.PerspectiveCamera(70, this.viewport.aspectRatio, 0.1, 1000);
    // this.camera.position.z = 1.5;
  }

  addMesh() {
    this.geometry = new THREE.PlaneGeometry(1.5, 1.5, 32, 32);
    this.material = new THREE.ShaderMaterial({
      vertexShader: vertex,
      fragmentShader: fragment,
      side: THREE.DoubleSide,
      //wireframe: true,
      uniforms: {
        matcap2: { value: new THREE.TextureLoader().load(matcap2) },
        matcap: { value: new THREE.TextureLoader().load(matcap) },
        uTime: { value: 0 },
        progress: { value: 0 },
        mouse: { value: new THREE.Vector2(0, 0) },
        resolution: { value: new THREE.Vector4() },
      },
    });
    //console.log(this.material.uniforms.uTime);
    this.mesh = new THREE.Mesh(this.geometry, this.material);
    this.scene.add(this.mesh);
  }

  addLight() {
    this.light = new THREE.DirectionalLight(0xffff, 0.08);
    this.light.position.set(-100, 0, -100);
    this.scene.add(this.light);
  }

  addControl() {
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    // this.controls.enableDamping = true;
    // this.controls.enablePan = true;
    // this.controls.enableZoom = true;
  }
  onWindowResize() {
    this.camera.aspect = this.viewport.aspectRatio;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(this.viewport.width, this.viewport.height);
    this.uWidth = this.container.offsetWidth;
    this.uHeight = this.container.offsetHeight;
    this.imageAspect = 1;
    let a1;
    let a2;

    if (this.uWidth / this.uHeight > this.imageAspect) {
      a1 = (this.uWidth / this.uHeight) * this.imageAspect;
      a2 = 1;
    } else {
      a1 = 1;
      a2 = this.uWidth / this.uHeight / this.imageAspect;
    }
    this.material.uniforms.resolution.value.x = this.uWidth;
    this.material.uniforms.resolution.value.y = this.uHeight;
    this.material.uniforms.resolution.value.z = a1;
    this.material.uniforms.resolution.value.w = a2;

    this.camera.updateProjectionMatrix();
  }
  settings() {
    this.settings = { progress: 0 };
    this.gui = new GUI();
    this.cameraFolder = this.gui.addFolder("camera");
    this.cameraFolder.add(this.camera.position, "x", -5, 5);
    this.cameraFolder.add(this.camera.position, "y", -5, 5);
    this.cameraFolder.add(this.camera.position, "z", -5, 5);
    this.cameraFolder.open();
    this.gui.add(this.settings, "progress", 0, 1, 0.01);
  }
  render() {
    this.time += 0.05;
    this.material.uniforms.uTime.value = this.time;
    this.material.uniforms.progress.value = this.settings.progress;
    if (this.mouse) {
      this.material.uniforms.mouse.value = this.mouse;
    }
    //console.log(this.mouse);
    //console.log(this.material.uniforms.uTime);
    this.renderer.render(this.scene, this.camera);
    window.requestAnimationFrame(this.render.bind(this));
  }
}

new WebGL();
