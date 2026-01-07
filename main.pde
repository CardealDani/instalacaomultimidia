enum Modo {
  DESIGN,
    SOM,
    TAMANHO,
    PERSONAGEM
}

Modo modoAtual = Modo.DESIGN;
Slider sliderTamanho;
Slider sliderForma;
Botao[] botoes = new Botao[4];
ArrayList<Bola> bolas = new ArrayList<Bola>();
color corBolinhas = color(255, 0, 0);
int formaBola = 0; // 0=circulo, 1=quadrado, 2=triangulo
float tamanhoBola = 20;

int formaPersonagem = 0;

void setup() {
  size(1000, 600);
  textSize(14);
  
  sliderTamanho = new Slider(160, 100, 150, 10, 80, tamanhoBola);
  sliderForma   = new Slider(240, 100, 150, 0, 2, formaBola);
  
  botoes[0] = new Botao(0, 0, 100, 150, "Design", Modo.DESIGN);
  botoes[1] = new Botao(0, 150, 100, 150, "Som", Modo.SOM);
  botoes[2] = new Botao(0, 300, 100, 150, "Tamanho", Modo.TAMANHO);
  botoes[3] = new Botao(0, 450, 100, 150, "Personagem", Modo.PERSONAGEM);

  // 🔴 cria bolinhas
  for (int i = 0; i < 20; i++) {
    bolas.add(new Bola());
  }
}


void draw() {
  background(255);

  desenharSidebar();
  desenharPainel();
  desenharBolinhas();
}

void desenharBolinhas() {
  for (Bola b : bolas) {
    b.update();
    b.draw();
  }
}

void desenharSidebar() {
  for (Botao b : botoes) {
    b.desenhar();
  }
}

void mousePressed() {
  for (Botao b : botoes) {
    if (b.clicado()) {
      modoAtual = b.modo;
    }
  }

  if (modoAtual == Modo.TAMANHO) {
    sliderTamanho.pressionar();
    sliderForma.pressionar();
  }
}

void mouseReleased() {
  sliderTamanho.soltar();
  sliderForma.soltar();
}

void desenharPainel() {
  fill(255, 0, 0);
  rect(100, 0, 200, height);

  switch (modoAtual) {
  case DESIGN:
    painelDesign();
    break;

  case SOM:
    break;

  case TAMANHO:
    painelTamanho();
    break;

  case PERSONAGEM:
    break;
  }
}

void painelDesign() {
  fill(255);
  text("DESIGN", 150, 50);
  text("Cor das bolinhas", 150, 100);
  text("Background", 150, 140);
}
void painelTamanho() {
  fill(255);
  text("TAMANHO", 150, 50);

  text("Tamanho da bolinha", 200, 95);
  sliderTamanho.desenhar();
  sliderTamanho.atualizar();
  tamanhoBola = sliderTamanho.valor;

  text("Forma da bolinha", 200, 155);
  sliderForma.desenhar();
  sliderForma.atualizar();
formaBola = parseInt(sliderForma.valor);
}


class Botao {
  float x, y, w, h;
  String label;
  Modo modo;

  Botao(float x, float y, float w, float h, String label, Modo modo) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.modo = modo;
  }

  void desenhar() {
    fill(modoAtual == modo ? color(200, 200, 255) : 255);
    rect(x, y, w, h);

    fill(0);
    textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  }

  boolean clicado() {
    return mouseX > x && mouseX < x+w &&
      mouseY > y && mouseY < y+h;
  }
}

class Bola {
  PVector pos, vel;

  Bola() {
    pos = new PVector(random(300+tamanhoBola, width), random(height));
    vel = PVector.random2D().mult(3);
  }

  void update() {
    pos.add(vel);

    if (pos.x-(tamanhoBola/2) < 300 || pos.x + (tamanhoBola/2) > width) vel.x *= -1;
    if (pos.y-(tamanhoBola/2) < 0 || pos.y + (tamanhoBola/2) > height) vel.y *= -1;
  }

  void draw() {
    fill(corBolinhas);

    switch (formaBola) {
    case 0:
      ellipse(pos.x, pos.y, tamanhoBola, tamanhoBola);
      break;
    case 1:
      rect(pos.x, pos.y, tamanhoBola, tamanhoBola);
      break;
    case 2:
      triangle(
        pos.x, pos.y - tamanhoBola/2,
        pos.x - tamanhoBola/2, pos.y + tamanhoBola/2,
        pos.x + tamanhoBola/2, pos.y + tamanhoBola/2
        );
      break;
    }
  }
}

class Slider {
  float x, y, h;
  float min, max;
  float valor;
  boolean ativo = false;

  Slider(float x, float y, float h, float min, float max, float valorInicial) {
    this.x = x;
    this.y = y;
    this.h = h;
    this.min = min;
    this.max = max;
    this.valor = valorInicial;
  }

  void desenhar() {
    // trilho vertical
    stroke(180);
    line(x, y, x, y + h);

    // posição do handle (vertical)
    float posY = map(valor, min, max, y + h, y);
    noStroke();
    fill(255);
    ellipse(x, posY, 12, 12);
  }

  void atualizar() {
    if (ativo) {
      valor = map(mouseY, y + h, y, min, max);
      valor = constrain(valor, min, max);
    }
  }

  void pressionar() {
    float posY = map(valor, min, max, y + h, y);
    if (dist(mouseX, mouseY, x, posY) < 10) {
      ativo = true;
    }
  }

  void soltar() {
    ativo = false;
  }
}

