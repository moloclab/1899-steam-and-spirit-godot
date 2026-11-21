# Estrae una palette riproducibile senza modificare gli asset sorgenti.
param([string]$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public class PaletteSample {
    public string Name, Category, Family;
    public int Width, Height, Frames;
    public long Pixels;
    public Dictionary<int,double> Hist = new Dictionary<int,double>();
}
public static class Palette1899 {
    // I bin RGB a 5 bit accorpano le piccole oscillazioni dei JPG.
    static int Bin(int rgb) { return ((rgb>>19)&31)*1024+((rgb>>11)&31)*32+((rgb>>3)&31); }
    static double Linear(double c) { c/=255; return c<=0.04045 ? c/12.92 : Math.Pow((c+0.055)/1.055,2.4); }
    static double F(double v) { return v>0.008856 ? Math.Pow(v,1.0/3) : 7.787*v+16.0/116; }
    static double[] Lab(int rgb) {
        double r=Linear((rgb>>16)&255),g=Linear((rgb>>8)&255),b=Linear(rgb&255);
        double x=F((r*.4124564+g*.3575761+b*.1804375)/.95047);
        double y=F(r*.2126729+g*.7151522+b*.0721750);
        double z=F((r*.0193339+g*.1191920+b*.9503041)/1.08883);
        return new double[]{116*y-16,500*(x-y),200*(y-z)};
    }
    static double Dist(double[] a,double[] b) { double x=a[0]-b[0],y=a[1]-b[1],z=a[2]-b[2]; return x*x+y*y+z*z; }
    public static string Hex(int c) { return "#"+c.ToString("X6"); }
    public static List<PaletteSample> Samples = new List<PaletteSample>();
    public static int[] Build(string source) {
        Samples.Clear();
        // Le frequenze GIF determinano i rappresentanti quando disponibili.
        var exact = new Dictionary<int,long>(); var gifExact = new Dictionary<int,long>();
        foreach(string path in Directory.GetFiles(source).OrderBy(p=>p,StringComparer.Ordinal)) {
            string ext=Path.GetExtension(path).ToLowerInvariant();
            if(ext!=".gif" && ext!=".jpg") continue;
            using(var im=Image.FromFile(path)) {
                string name=Path.GetFileNameWithoutExtension(path).ToLowerInvariant();
                string category="objects", family=name;
                if(Regex.IsMatch(name,@"^(m_|opt_|panel_|inv|screen_|tut_|bubblebackground|footer|hotspot|label$|option$|chapterback|back$|pg$|x$|zone$)")) category="interface";
                else if(name.StartsWith("o_")) category="inventory";
                else if(Regex.IsMatch(name,@"^(churchill|chef|cook$|harris$|kelvin|sleeper|smoker|zuavo)|(?:fisher|pelican|merchant|algerian|smith|zuavi|zuavo|gallieni|officer|worker|ravanalona|ranavalona|platoon|walker$|captain$|guard$|operator)")) category="characters";
                else if(ext==".jpg" || name=="backcapitol") category="backgrounds";
                if(category=="characters") {
                    var match=Regex.Match(name,@"^(churchillarab|churchillsub|churchill|chef|kelvin|zuavo|sleeper)|^(r\d+_(?:fisher|pelican|zuavo|operator|walker))");
                    if(match.Success) family=match.Value;
                } else {
                    family=Regex.Replace(family,@"(?:open|close|closed|down|up|off|on|broken|stand|roll|run|stop|hard|soft|empty|full|left|right|\d+)$", "");
                    if(category=="interface" && name.StartsWith("tut_")) family="tutorial";
                    if(category=="backgrounds" && name.StartsWith("sky")) family="sky";
                }
                var s=new PaletteSample {Name=Path.GetFileName(path),Category=category,Family=family,Width=im.Width,Height=im.Height};
                var dimension=new FrameDimension(im.FrameDimensionsList[0]);
                s.Frames=im.GetFrameCount(dimension);
                // Ogni file pesa una volta, indipendentemente dal numero di frame.
                for(int frame=0;frame<s.Frames;frame++) {
                    im.SelectActiveFrame(dimension,frame);
                    using(var bm=new Bitmap(im.Width,im.Height,PixelFormat.Format32bppArgb)) {
                        using(var graphics=Graphics.FromImage(bm)) { graphics.Clear(Color.Transparent); graphics.DrawImageUnscaled(im,0,0); }
                        for(int y=0;y<bm.Height;y++) for(int x=0;x<bm.Width;x++) {
                            Color c=bm.GetPixel(x,y); if(c.A==0) continue;
                            int rgb=c.ToArgb()&0xffffff,bin=Bin(rgb);
                            if(!s.Hist.ContainsKey(bin)) s.Hist[bin]=0;
                            s.Hist[bin]++; s.Pixels++;
                            if(!exact.ContainsKey(rgb)) exact[rgb]=0; exact[rgb]++;
                            if(ext==".gif") { if(!gifExact.ContainsKey(rgb)) gifExact[rgb]=0; gifExact[rgb]++; }
                        }
                    }
                }
                if(s.Pixels>0) { foreach(int key in s.Hist.Keys.ToArray()) s.Hist[key]/=s.Pixels; }
                Samples.Add(s);
            }
        }
        // Prima media per famiglia, poi per categoria: la superficie non decide il peso.
        var categoryWeight=new Dictionary<string,double>{{"backgrounds",.25},{"objects",.30},{"characters",.25},{"inventory",.15},{"interface",.05}};
        var weight=new double[32768];
        foreach(var cat in Samples.Where(s=>s.Pixels>0).GroupBy(s=>s.Category)) {
            var families=cat.GroupBy(s=>s.Family).ToArray();
            foreach(var fam in families) foreach(var s in fam)
                foreach(var pair in s.Hist) weight[pair.Key]+=pair.Value*categoryWeight[cat.Key]/families.Length/fam.Count();
        }
        // Ogni rappresentante e' un colore effettivamente presente nelle sorgenti.
        var representative=new int[32768]; var bestCount=new long[32768];
        foreach(var pair in exact.OrderBy(p=>p.Key)) { int bin=Bin(pair.Key); if(pair.Value>bestCount[bin]) {bestCount[bin]=pair.Value; representative[bin]=pair.Key;} }
        Array.Clear(bestCount,0,bestCount.Length);
        foreach(var pair in gifExact.OrderBy(p=>p.Key)) { int bin=Bin(pair.Key); if(pair.Value>bestCount[bin]) {bestCount[bin]=pair.Value; representative[bin]=pair.Key;} }
        int[] bins=Enumerable.Range(0,32768).Where(i=>weight[i]>0).ToArray();
        double[][] lab=bins.Select(i=>Lab(representative[i])).ToArray();
        var centers=new List<double[]>();
        int seed=Enumerable.Range(0,bins.Length).OrderByDescending(i=>weight[bins[i]]).First();
        centers.Add((double[])lab[seed].Clone());
        var nearest=Enumerable.Repeat(double.MaxValue,bins.Length).ToArray();
        // Inizializzazione deterministica, senza casualita'.
        while(centers.Count<128) {
            int next=0; double score=-1;
            for(int i=0;i<bins.Length;i++) { nearest[i]=Math.Min(nearest[i],Dist(lab[i],centers.Last())); double v=nearest[i]*Math.Sqrt(weight[bins[i]]); if(v>score){score=v;next=i;} }
            centers.Add((double[])lab[next].Clone());
        }
        var assignment=new int[bins.Length];
        for(int iteration=0;iteration<40;iteration++) {
            var sums=new double[128,4];
            for(int i=0;i<bins.Length;i++) {
                int index=0;double distance=double.MaxValue;
                for(int k=0;k<128;k++){double d=Dist(lab[i],centers[k]);if(d<distance){distance=d;index=k;}}
                assignment[i]=index;double w=weight[bins[i]];sums[index,3]+=w;
                for(int c=0;c<3;c++) sums[index,c]+=lab[i][c]*w;
            }
            double shift=0;
            for(int k=0;k<128;k++) if(sums[k,3]>0) {var next=new double[]{sums[k,0]/sums[k,3],sums[k,1]/sums[k,3],sums[k,2]/sums[k,3]};shift+=Dist(next,centers[k]);centers[k]=next;}
            if(shift<.00001) break;
        }
        var selected=new List<int>();
        for(int k=0;k<128;k++) {
            int index=Enumerable.Range(0,bins.Length).Where(i=>assignment[i]==k).OrderBy(i=>Dist(lab[i],centers[k])).First();
            selected.Add(representative[bins[index]]);
        }
        // Raggruppamento visivo per famiglia cromatica e luminosita'.
        return selected.OrderBy(rgb=> {
            Color c=Color.FromArgb((rgb>>16)&255,(rgb>>8)&255,rgb&255);
            return c.GetSaturation()<.15 ? -1 : (int)((c.GetHue()+15)%360/30);
        }).ThenBy(rgb=>Lab(rgb)[0]).ToArray();
    }
    // Campioni senza testo per usare la palette come riferimento visivo.
    public static void DrawSwatches(int[] colors,string path) {
        using(var bitmap=new Bitmap(256,128)) using(var g=Graphics.FromImage(bitmap)) {
            for(int i=0;i<colors.Length;i++) {
                using(var brush=new SolidBrush(Color.FromArgb(255,(colors[i]>>16)&255,(colors[i]>>8)&255,colors[i]&255)))
                    g.FillRectangle(brush,(i%16)*16,(i/16)*16,16,16);
            }
            bitmap.Save(path,ImageFormat.Png);
        }
    }
    public static void Draw(int[] colors,string path) {
        using(var bitmap=new Bitmap(1440,870)) using(var g=Graphics.FromImage(bitmap))
        using(var title=new Font("Segoe UI",22,FontStyle.Bold)) using(var font=new Font("Consolas",11))
        using(var text=new SolidBrush(Color.FromArgb(230,230,230))) {
            g.Clear(Color.FromArgb(24,26,29));
            g.DrawString("1899 / PALETTE BASE / 128 COLORI",title,text,24,18);
            g.DrawString("Derivata da EP01/img - riferimento flessibile per il redesign",font,text,26,62);
            for(int i=0;i<colors.Length;i++) {
                int x=24+(i%16)*87,y=108+(i/16)*92;
                using(var brush=new SolidBrush(Color.FromArgb(255,(colors[i]>>16)&255,(colors[i]>>8)&255,colors[i]&255))) g.FillRectangle(brush,x,y,78,56);
                g.DrawString(Hex(colors[i]),font,text,x,y+60);
            }
            bitmap.Save(path,ImageFormat.Png);
        }
    }
}
'@
$source = Join-Path $ProjectRoot 'EP01/img'
$destination = Join-Path $ProjectRoot 'godot/palette'
New-Item -ItemType Directory -Force $destination | Out-Null
$colors = [Palette1899]::Build($source)
if (($colors | Sort-Object -Unique).Count -ne 128) { throw 'La palette deve contenere 128 colori distinti.' }
[Palette1899]::Draw($colors, (Join-Path $destination '1899-base-128.png'))
[Palette1899]::DrawSwatches($colors, (Join-Path $destination '1899-base-128-swatches.png'))
$hex = @($colors | ForEach-Object { [Palette1899]::Hex($_) })
$data = [ordered]@{ name='1899 Base 128'; source='EP01/img'; strict=$false; colors=$hex }
$data | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $destination '1899-base-128.json')
$gpl = @('GIMP Palette','Name: 1899 Base 128','Columns: 16','# Flexible reference palette derived from EP01/img')
for ($i=0; $i -lt 128; $i++) {
    $c=$colors[$i]
    $gpl += ('{0,3} {1,3} {2,3} {3}' -f (($c -shr 16) -band 255),(($c -shr 8) -band 255),($c -band 255),$hex[$i])
}
$gpl | Set-Content -Encoding ASCII (Join-Path $destination '1899-base-128.gpl')
[Palette1899]::Samples | Select-Object Name,Category,Family,Width,Height,Frames,Pixels | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $PSScriptRoot 'sources.csv')
[Palette1899]::Samples | Group-Object Category | Select-Object Name,Count | Format-Table
Write-Output ('Colori distinti: {0}; file analizzati: {1}; frame: {2}' -f $hex.Count,[Palette1899]::Samples.Count,([Palette1899]::Samples | Measure-Object Frames -Sum).Sum)
