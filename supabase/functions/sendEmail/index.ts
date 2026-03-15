import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import nodemailer from "npm:nodemailer";

serve(async (req) => {
  try {
    const { to, subject, text } = await req.json();

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "ikam7247@gmail.com",
        pass: "iduk iibl ymql efwi",
      },
    });

    await transporter.sendMail({
      from: "ikam7247@gmail.com",
      to,
      subject,
      text,
    });

    return new Response(JSON.stringify({ message: "Email sent!" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});